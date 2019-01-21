//
//  ViewController.m
//  CylinerExpansionAnimation
//
//  Created by zhangkai on 2019/1/4.
//  Copyright © 2019 zhangkai. All rights reserved.
//

#import "ViewController.h"
#import "opencv2/opencv.hpp"
#include "esUtil.h"
#include <string.h>
using namespace std;

#include <time.h>
#include <sys/time.h>

//从安卓工程里提取
#include "vecmath.h"
using namespace ndk_helper;

#include "tapCamera.h"

#define PI 3.1415926f

#define intervalY    2
#define intervalX   4

@interface ViewController ()
{
    GLuint _programObject;
    GLuint _attrPos;
    GLuint _attrUV;
    GLuint _samTexture;
    GLuint _mvpMatrix;
    
    GLuint _textureID;
    
    
    GLfloat _radius;
    
    GLfloat *_vertices;
    GLfloat *_numIndices;
    
    GLfloat *vertices;
    
    GLuint _photoWidth;
    GLuint _photoHeight;
    unsigned char* photoByts;
    
    GLuint _drawableWidth;
    GLuint _drawableHeight;
    
    // MVP matrix
    ESMatrix  mvpMatrix;
    
    //use tap Camera instead
    TapCamera tap_Camera_;
    bool thread_running_;
    
    // duplicate location
    int duplicate_location; //[0 , NUMBER_OF_POINTS-1]
    GLfloat _defaultRadius;
    
    int expandIndex_;
}

@end


int     STEP  = 20;

@implementation ViewController

void CheckGlError(const char* op)
{
    for (GLint error = glGetError(); error; error = glGetError())
    {
        printf("after %s() glError (0x%x)\n", op, error);
    }
}

static double GetCurrentTime() {
    struct timeval time;
    gettimeofday(&time, NULL);
    double ret = time.tv_sec + time.tv_usec * 1.0 / 1000000.0;
    return ret;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self InitData];
    
    [self SaveImageToLocalPath];
    [self LoadTexture];
    
    [self InitGLView];
    [self AddGestureDetector];
    
    [self startTimer];
}

- (void) InitData
{
    _defaultRadius = 1.0f;
    duplicate_location = 0;
    _radius = _defaultRadius;
    expandIndex_ = 0;
    
    //init
    tap_Camera_.SetFlip(1.f, 0.f, -1.f);
    tap_Camera_.SetPinchTransformFactor(2.f, 2.f, 8.f);
}

- (void) startTimer
{
    //这个方法会和主线程阻塞，导致判断失败---因此我们必须放在一个单独的线程中进行处理.
    //更新旋转操作
//    NSTimer *timer = [ NSTimer  scheduledTimerWithTimeInterval: 0.02
//                                               target: self
//                                             selector: @selector ( onTimer: )
//                                             userInfo:nil
//                                              repeats: YES ];
    
    thread_running_ = true;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while(thread_running_)
        {
            [self onTimer];
            [NSThread sleepForTimeInterval:0.2f];
        }
    });
    
}

- (void) dealloc
{
    thread_running_ = false;
}

-(void) onTimer
{
    [self Update:GetCurrentTime()];
}

-(void) Update:(double)time
{
    tap_Camera_.Update(time);
    [self update];
}

//添加手势识别--圆柱体我们只绕y轴旋转做加速测试
- (void) AddGestureDetector
{
    //左右滑动
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc]
                                             initWithTarget:self
                                             action:@selector(pandRecognizer:)];
    [self.view addGestureRecognizer:panRecognizer];
}


- (void) pandRecognizer:(id)sender {
    UIPanGestureRecognizer *panRecognizer = (UIPanGestureRecognizer *)sender;
    
    GLKView *view = (GLKView *)self.view;
    
    CGPoint point = [panRecognizer locationInView:self.view];
    ndk_helper::Vec2 v(point.x,point.y);
    
//    printf("x:%f --- y:%f \n" , point.x ,point.y);
    
    //苹果是4*4,安卓是2*2
    //把点转化为矩阵坐标
    ndk_helper::Vec2 transformV = ndk_helper::Vec2(4.0f, 4.0f) * v /
    ndk_helper::Vec2(_drawableWidth,_drawableHeight) - ndk_helper::Vec2(1.f, 1.f);
    
    //touch begin
    if (panRecognizer.state == UIGestureRecognizerStateBegan)
    {
//        printf("drag start\n");
        tap_Camera_.BeginDrag(transformV);
    }
    //touch move
    else if(panRecognizer.state == UIGestureRecognizerStateChanged)
    {
//        printf("drag move\n");
        tap_Camera_.Drag(transformV);
    }
    //touch end
    else if(panRecognizer.state == UIGestureRecognizerStateEnded)
    {
//        printf("drag end\n");
        tap_Camera_.EndDrag();
    }
}


- (void) SaveImageToLocalPath
{
    NSString* resPath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"jpg"];
    NSURL *url = [[NSURL alloc] initFileURLWithPath:resPath];
    
    NSData* fishdemoData = [NSData dataWithContentsOfURL:url];
    
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentDirectory = [paths objectAtIndex:0];
    NSString* imgPath = [documentDirectory stringByAppendingString:@"/test.jpg"];
    [fishdemoData writeToFile:imgPath atomically:YES];
}

- (void) LoadTexture
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentDirectory = [paths objectAtIndex:0];
    NSString* imgPath = [documentDirectory stringByAppendingString:@"/test.jpg"];
    
    cv::Mat image = cv::imread([imgPath UTF8String]);
    _photoWidth = image.cols;
    _photoHeight = image.rows;
    
    int pixelLength = _photoWidth * _photoHeight * 3;
    if(photoByts != nullptr)
    {
        delete [] photoByts;
        photoByts = nullptr;
    }
    
    photoByts = new unsigned char[pixelLength];
    memcpy(photoByts, image.data, pixelLength * sizeof(unsigned char));
}


- (void) InitGLView {
    //init
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;//只有属性置顶后接口才会回调
}


-(void) InitOpenGL
{
    //编译shader
    [self CompileShader];
    
    _defaultRadius = 1.0f;
    _radius = _defaultRadius;
    
    //建立顶点和纹理坐标
//    [self InitVertices:_radius];
    [self buildModels:0 radius:1.0f];
}

- (void) CompileShader
{
    const char *vertShader =
    
    "precision highp float;                                         \n"
    "attribute vec3 a_Position;             \n"
    "attribute vec2 a_TexCoord;             \n"
    
    "uniform mat4   u_MvpMatrix;            \n"
    "varying vec2   v_TexCoord;             \n"
    
    "void main()                            \n"
    "{                                      \n"
    "   v_TexCoord = a_TexCoord;            \n"
    "   gl_Position = u_MvpMatrix * vec4(a_Position,1.0); \n"
    "}                                      \n"
    ;
    
    const char *fragmentShader =

    "precision highp float;                                         \n"
    "varying vec2    v_TexCoord;                                    \n"
    "uniform sampler2D  u_TextureOES;                               \n"
    "void main()                                                    \n"
    "{                                                              \n"
    "   gl_FragColor = texture2D(u_TextureOES,v_TexCoord).bgra;         \n"
    "}                                                              \n"
    ;
    
    
    _programObject = esLoadProgram(vertShader, fragmentShader);
    
    _attrPos = glGetAttribLocation(_programObject, "a_Position");
    _attrUV  = glGetAttribLocation(_programObject, "a_TexCoord");
    
    _samTexture = glGetUniformLocation(_programObject, "u_TextureOES");
    _mvpMatrix = glGetUniformLocation(_programObject, "u_MvpMatrix");
    
    CheckGlError("step1");
    
    glGenTextures(1, &_textureID);
    
    glBindTexture(GL_TEXTURE_2D, _textureID);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    CheckGlError("step2");
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}

- (void)InitVertices:(GLfloat) radius
{
    //根据半径来进行计算
    GLfloat initRadius = 1.0f;
    
    //规定弧长
    GLfloat perimeter  = 2 * PI * initRadius;
    GLfloat perimeter2 = 2 * PI * radius; //要贴上的圆柱体
    
    GLfloat angle = perimeter / perimeter2 * 360.0f;
    
    GLfloat startAngle = 90 - (angle / 2) ;
    GLfloat angleStep = angle / STEP;
    
    
    
    if(_vertices != nullptr)
    {
        delete[] _vertices;
        _vertices = nullptr;
    }
    _vertices = new GLfloat [(STEP - 1) * 6 *5]; //一共走19次，每次一个正方形，包括6个点，每个点包括[x,y,z,uv]5个坐标.


    GLfloat x,z;
    GLfloat x1,z1;
    GLfloat angleCompute = 0.0f;

    GLfloat angleCompute1 = 0.0f;
    GLfloat angle1;

    GLfloat u,v;
    GLfloat u1,v1;

    // 2  1
    // 4  3

    int index = 0;

    GLfloat up = 1.0f;
    GLfloat down = -1.0f;

    GLfloat uv_step = 1.0f / STEP;

    for(int i = 0 ; i < STEP - 1 ; i++)
    {
        angleCompute = startAngle + i * angleStep;
        angle = (90 - angleCompute) *  PI / 180 ;

        angleCompute1 = startAngle + (i+1) * angleStep;
        angle1 = (90 - angleCompute1) *  PI / 180 ;

        x =  radius * cosf( angle );
        z =  radius * sinf( angle );
        
        //printf("x-- %f -- y:%f -- z:%f \n" , x,up,z);

        x1 =  radius * cosf( angle1 );
        z1 =  radius * sinf( angle1 );

        u = i * uv_step;
        u1 = u + uv_step;

        // 124 / 413
        _vertices[index++] = x;
        _vertices[index++] = up;
        _vertices[index++] = z;

        _vertices[index++] = u ;
        _vertices[index++] = 1.0;

        _vertices[index++] = x1;
        _vertices[index++] = up;
        _vertices[index++] = z1;

        _vertices[index++] = u1 ;
        _vertices[index++] = 1.0;

        _vertices[index++] = x1;
        _vertices[index++] = down;
        _vertices[index++] = z1;

        _vertices[index++] = u1 ;
        _vertices[index++] = 0.0;

        _vertices[index++] = x1;
        _vertices[index++] = down;
        _vertices[index++] = z1;

        _vertices[index++] = u1 ;
        _vertices[index++] = 0.0;

        _vertices[index++] = x;
        _vertices[index++] = up;
        _vertices[index++] = z;

        _vertices[index++] = u ;
        _vertices[index++] = 1.0;

        _vertices[index++] = x;
        _vertices[index++] = down;
        _vertices[index++] = z;

        _vertices[index++] = u ;
        _vertices[index++] = 0.0;
    }

//    printf("count :%d -- index:%d \n" , (STEP - 1) * 6 * 5 , index);
    
//    int YAngle = 0;
//    int XAngle = 0;
//
//    int i = 0;
//
//    int rowtick = 0;
//    int coltick = 0;
//
//    double perRadius = M_PI / 180.0; //角度转弧度
//    (vertices) = (GLfloat*)malloc((180 / intervalY) * (360 / (intervalX)) * 6 * 5 * sizeof(GLfloat));
//
//    for (YAngle = 0, rowtick = 0; YAngle < 180; YAngle += intervalY, rowtick++) //将Y轴切割为90份
//    {
//
//        float Y0 = -cosf((float)YAngle * perRadius);
//        float Y1 = -cosf((float)(YAngle + intervalY) * perRadius);
//
//        //通过线性插值计算得出----
//        //        float R0 = sinf((float)YAngle*perRadius); //sin0-180 为0-1永远是正直的
//        //        float R1 = sinf((float)(YAngle + intervalY) * perRadius);
//
//        float R0 = 1.0f;
//        float R1 = 1.0f;
//
//
//
//        //等比例计算  -- 如果是bmp的位图rgb,那么就不需要1.0 -
//        float V0 = 1.0 - (float)YAngle / 180.0;
//        float V1 = 1.0 - (float)(YAngle + intervalY) / 180.0;
//
//        for (XAngle = 0, coltick = 0; XAngle < 360; XAngle += intervalX, coltick++)
//        {
//            // 第1个顶点
//            float a1x = R0 * cosf((float)XAngle * perRadius);
//            float a1y = Y0;
//            float a1z = -R0 * sinf((float)XAngle * perRadius);
//
//            float a1u = 0;
//            a1u = 1.0 - (float)XAngle / 360.0;
//            float a1v = V0;
//
//            //第2个顶点
//            float a2x = R1 * cosf((float)XAngle * perRadius);
//            float a2y = Y1;
//            float a2z = -R1 * sinf((float)XAngle * perRadius);
//
//            float a2u = 0;
//            a2u = 1.0 - (float)XAngle / 360.0;
//            float a2v = V1;
//
//            //第3个顶点
//            float a3x = R1 * cosf((float)(XAngle + intervalX) * perRadius);
//            float a3y = Y1;
//            float a3z = -R1 * sinf((float)(XAngle + intervalX) * perRadius);
//
//            float a3u = 0.0f;
//            a3u = 1.0 - (float)(XAngle + intervalX) / 360.0;
//            float a3v = V1;
//
//            //第4个顶点
//            float a4x = R0 * cosf((float)(XAngle + intervalX) * perRadius);
//            float a4y = Y0;
//            float a4z = -R0 * sinf((float)(XAngle + intervalX) * perRadius);
//
//            float a4u = 0.0f;
//            a4u = 1.0 - (float)(XAngle + intervalX) / 360.0;
//            float a4v = V0;
//
//            //构建第一个三角形
//            (vertices)[i++] = a1x; (vertices)[i++] = a1y; (vertices)[i++] = a1z;  (vertices)[i++] = a1u; (vertices)[i++] = a1v;
//            (vertices)[i++] = a2x; (vertices)[i++] = a2y; (vertices)[i++] = a2z;  (vertices)[i++] = a2u; (vertices)[i++] = a2v;
//            (vertices)[i++] = a3x; (vertices)[i++] = a3y; (vertices)[i++] = a3z;  (vertices)[i++] = a3u; (vertices)[i++] = a3v;
//
//            //构建第二个三角形
//            (vertices)[i++] = a3x; (vertices)[i++] = a3y; (vertices)[i++] = a3z;  (vertices)[i++] = a3u; (vertices)[i++] = a3v;
//            (vertices)[i++] = a4x; (vertices)[i++] = a4y; (vertices)[i++] = a4z;  (vertices)[i++] = a4u; (vertices)[i++] = a4v;
//            (vertices)[i++] = a1x; (vertices)[i++] = a1y; (vertices)[i++] = a1z;  (vertices)[i++] = a1u; (vertices)[i++] = a1v;
//
//        }
//    }
    
}

- (void) update
{
    ESMatrix perspective;
    ESMatrix modelview;
    float    aspect;
    
    // Compute the window aspect ratio
    aspect = ( GLfloat ) _drawableWidth / _drawableHeight;
    
    //有问题?
    //Z方向的方向是从屏幕正中间射出来----
    
    // Generate a perspective matrix with a 60 degree FOV
    esMatrixLoadIdentity ( &perspective );
    esPerspective ( &perspective, 60.0f, aspect, 1.0f, 100.0f );
    
    esMatrixLoadIdentity ( &modelview );
    
    float distance = -4.0f + (_radius - _defaultRadius);
    
    // Translate away from the viewer
    esTranslate ( &modelview, 0.0, 0.0,  distance );
    
//    esRotate(&modelview, 90, 0.0, 1.0F, 0.0f);
    
    //再次进行乘法，进行旋转
    ESMatrix rotationMatrix;
    memcpy(rotationMatrix.m, tap_Camera_.GetRotationMatrix().Ptr(), 16*sizeof(float));
    esMatrixMultiply(&modelview, &rotationMatrix ,&modelview );
    
    // Compute the final MVP by multiplying the
    // modevleiw and perspective matrices together
    esMatrixMultiply ( &mvpMatrix, &modelview, &perspective );
}


- (void) drawFrame:(NSUInteger)drawableWidth height:(NSUInteger)drawableHeight
{
    glViewport(0, 0, drawableWidth, drawableHeight);
    
    // Clear the color buffer
    glClear ( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    
    glUseProgram ( _programObject );
    
    CheckGlError("draw 1");
    
    //数组
    GLfloat vertices [5*6]=
    {
        1.0f , -1.0f ,0.0f , 1.0f ,0.0f , // bottom right
        1.0f,1.0f,0.0f , 1.0 , 1.0f , // top right
        -1.0f,-1.0f, 0.0f , 0.0f ,0.0f ,// bottom left
        
        1.0f,1.0f,0.0f , 1.0 , 1.0f , // top right
        -1.0f,1.0f,0.0f , 0.0f ,1.0f , // top left
        -1.0f,-1.0f, 0.0f , 0.0f ,0.0f ,// bottom left
    };
    
    //绑定顶点和纹理坐标
    glEnableVertexAttribArray( _attrPos );
    glVertexAttribPointer ( _attrPos,
                           3,
                           GL_FLOAT,
                           GL_FALSE,
                           3 * sizeof ( GLfloat ),
                           //_vertices
                           vertexBuf
                           );
    
    glEnableVertexAttribArray(_attrUV);
    glVertexAttribPointer ( _attrUV,
                           3,
                           GL_FLOAT,
                           GL_FALSE,
                           2 * sizeof ( GLfloat ),
                           //&_vertices[3]
                           uvBuf
                           );
    
    CheckGlError("draw 2");
    
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _textureID);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, _photoWidth, _photoHeight, 0, GL_RGB, GL_UNSIGNED_BYTE, photoByts);
    
    CheckGlError("draw 3");
    
    glUniform1i(_samTexture, 0);
    // Load the MVP matrix
    glUniformMatrix4fv ( _mvpMatrix , 1, GL_FALSE, ( GLfloat * ) &mvpMatrix.m[0][0] );
    
    CheckGlError("draw 4");
    
    //check
    //printf("the count is:%d \n" , sizeof(_vertices) / sizeof(GLfloat) );
    //glDrawArrays(GL_TRIANGLES, 0,  6  );
    
    //glDrawArrays(GL_TRIANGLES, 0,  (STEP - 1) * 6  );
    
    glDrawElements ( GL_TRIANGLES, (NUMBER_OF_POINT - 1) * 6, GL_UNSIGNED_INT, index_buf);
    
    //glDrawArrays(GL_TRIANGLES, 0,  (180 / intervalY) * (360 / (intervalX)) * 6  );
    CheckGlError("draw 5");
}


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    if(_drawableWidth == 0 && _drawableHeight == 0)
    {
        _drawableWidth = view.drawableWidth;
        _drawableHeight = view.drawableHeight;
        
        [self update];
        // Do any additional setup after loading the view, typically from a nib.
        [self InitOpenGL];
    }

    [self drawFrame:view.drawableWidth height:view.drawableHeight];
}



const int NUMBER_OF_POINT = 101; //一定要为奇数，否则会引起计算问题
const int COUNT = (NUMBER_OF_POINT + 1) * 2 ; // 上下2根线+重合点
GLfloat *vertexBuf = new GLfloat [ (COUNT ) * 3 ]; //[x,y,z] 3个坐标
GLfloat *uvBuf = new GLfloat [ (COUNT ) * 2 ]; //[u,v] 2个坐标
int *index_buf = new int [ (NUMBER_OF_POINT - 1) * 6 ];

//UV滚动算法
//partIndex表示重合点的位置
- (void) buildModels:(int)partIndex radius:(CGFloat) radius_to_affix
{
    /////////////////////
    //STEP 1: xyz buffer
    /////////////////////

     //绘制top/bottom圆
     
    //根据半径来进行计算
    GLfloat initRadius = 1.0f;
    
   
    int count  = (NUMBER_OF_POINT-1) / 2 ;//左半部分的尺寸
    
    CGFloat startX,endX;
    CGFloat startZ,endZ;
    
    CGFloat each_of_angle = 360.f / ( NUMBER_OF_POINT - 1 ) ;
    CGFloat topY = 1.0f;
    
    CGFloat each_of_x = PI * radius_to_affix /  count ;
    //    CGFloat each_of_y = 2 * radius_to_affix / count ;
    
    int index = 0;
    
    // left part
    for(int i = 0 ; i < count + 1 ; i++)
    {
        startX = cosf( (90 + i * each_of_angle) * PI  / 180.f ) ;
        endX =   PI * radius_to_affix - i * each_of_x ;
        
        startZ = sinf ((90 + i * each_of_angle) * PI  / 180.f );
        endZ = -1.0f;//所有的点终点的z都是一样的
        
        CGFloat each_size_of_item_x = abs(startX + endX) / count;
        CGFloat each_size_of_item_z = abs(startZ - endZ) / count;
        
        int checkIndex = index;
        
        vertexBuf[index++] = startX - each_size_of_item_x * expandIndex_ ;
        vertexBuf[index++] = topY;
        vertexBuf[index++] = startZ - each_size_of_item_z * expandIndex_;
        
        if(i == partIndex) //重合点
        {
            vertexBuf[index++] = startX - each_size_of_item_x * expandIndex_ ;
            vertexBuf[index++] = topY;
            vertexBuf[index++] = startZ - each_size_of_item_z * expandIndex_;
            printf("(%f %f %f) \n" , vertexBuf[checkIndex] , vertexBuf[checkIndex+1] , vertexBuf[checkIndex+2]);
        }
        
        //重合点
        printf("(%f %f %f) \n" , vertexBuf[checkIndex] , vertexBuf[checkIndex+1] , vertexBuf[checkIndex+2]);
    }
    
    printf("the oppsite point \n");
    
    int SymmetricPoint = count;
    
    //right part -- x:oppsite
    for(int i = 1 ; i < count + 1 ; i++)
    {
        startX = cosf( (270 + i * each_of_angle) * PI  / 180.f ) ;
        endX =   i * each_of_x ;
        
        startZ = sinf ((270 + i * each_of_angle) * PI  / 180.f );
        endZ = -1.0f;//所有的点终点的z都是一样的
        
        CGFloat each_size_of_item_x = abs(endX - startX  ) / count;
        CGFloat each_size_of_item_z = abs(startZ - endZ) / count;
        
        int checkIndex = index;
        
        vertexBuf[index++] = startX + each_size_of_item_x * expandIndex_ ;
        vertexBuf[index++] = topY;
        vertexBuf[index++] = startZ - each_size_of_item_z * expandIndex_;
        
        if(i + SymmetricPoint == partIndex) //重合点
        {
            vertexBuf[index++] = startX - each_size_of_item_x * expandIndex_ ;
            vertexBuf[index++] = topY;
            vertexBuf[index++] = startZ - each_size_of_item_z * expandIndex_;
            printf("(%f %f %f) \n" , vertexBuf[checkIndex] , vertexBuf[checkIndex+1] , vertexBuf[checkIndex+2]);
        }
        
        //重合点
        printf("(%f %f %f) \n" , vertexBuf[checkIndex] , vertexBuf[checkIndex+1] , vertexBuf[checkIndex+2]);
    }
    
    printf("the bottom value  \n");
    
    //bottom
    for( int i = 0 ; i < NUMBER_OF_POINT + 1 ; i++)
    {
        int checkIndex = index;
        
        vertexBuf[index++] = vertexBuf[i*3 ];
        vertexBuf[index++] = vertexBuf[i*3 + 1] * -1.f;
        vertexBuf[index++] = vertexBuf[i*3 + 2];
        
        printf("(%f %f %f) \n" , vertexBuf[checkIndex] , vertexBuf[checkIndex+1] , vertexBuf[checkIndex+2]);
    }
    
    printf("index:%d --count:%d \n" , index , (COUNT ) * 3 );
    
//    //规定弧长
//    GLfloat perimeter  = 2 * PI * initRadius;
//    GLfloat perimeter2 = 2 * PI * radius_to_affix; //要贴上的圆柱体
//
//    //计算角度所占百分比 -- 角度
//    GLfloat angle = perimeter / perimeter2  * 360 ;
//
//
//    CGFloat startAngle = (360 - angle) + (angle - 180 ) / 2 ;
//    CGFloat each_of_angle = angle / (NUMBER_OF_POINT -1) ;
//
//    //top
//    CGFloat top_y = 1.0f;
//    for(int i = 0 ; i < NUMBER_OF_POINT ; i++)
//    {
//        angle = startAngle + i * each_of_angle;
//
//
//        vertexBuf[index++] = cosf(angle * PI / 180.f);
//        vertexBuf[index++] = top_y;
//        vertexBuf[index++] = sinf(angle * PI / 180.f);
//
//        if( i == partIndex )
//        {
//            vertexBuf[index++] = cosf(angle * PI / 180.f);
//            vertexBuf[index++] = top_y;
//            vertexBuf[index++] = sinf(angle * PI / 180.f);
//        }
//    }
//
//    //bottom
//    CGFloat bottom_y = -1.0f;
//    for(int i = 0 ; i < NUMBER_OF_POINT ; i++)
//    {
//        angle = startAngle + i * each_of_angle;
//
//
//        vertexBuf[index++] = cosf(angle * PI / 180.f);
//        vertexBuf[index++] = bottom_y;
//        vertexBuf[index++] = sinf(angle * PI / 180.f);
//
//        if( i == partIndex )
//        {
//            vertexBuf[index++] = cosf(angle * PI / 180.f);
//            vertexBuf[index++] = bottom_y;
//            vertexBuf[index++] = sinf(angle * PI / 180.f);
//        }
//    }
    

    /*
    
    CGFloat each_of_xyz = 2.0f / (NUMBER_OF_POINT - 1);
     
     //正方形的绘制方法
    CGFloat top_y = 1.0f;
    CGFloat top_z = 0.0f;
    
    //top
    for(int i = 0 ; i < NUMBER_OF_POINT ; i++)
    {
        vertexBuf[index++] = -1.0f +  i * each_of_xyz ;
        vertexBuf[index++] = top_y;
        vertexBuf[index++] = top_z;
        
        //copy duplicate point
        if(i  == partIndex)
        {
            vertexBuf[index++] = -1.0f +  i * each_of_xyz ;
            vertexBuf[index++] = top_y;
            vertexBuf[index++] = top_z;
        }
    }
    
    
    CGFloat bottom_y = -1.0f;
    CGFloat bottom_z = 0.0f;
    //bottom
    for(int i = 0 ; i < NUMBER_OF_POINT ; i++)
    {
        vertexBuf[index++] = -1.0f + i * each_of_xyz ;
        vertexBuf[index++] = bottom_y;
        vertexBuf[index++] = bottom_z;
        
        //copy duplicate point
        if(i  == partIndex)
        {
            vertexBuf[index++] = -1.0f +  i * each_of_xyz ;
            vertexBuf[index++] = bottom_y;
            vertexBuf[index++] = bottom_z;
        }
    }
     */
    
    printf("xyz index:%d --count:%d \n" , index,(COUNT ) * 3 );
    
    /////////////////////////////
    //STEP 2: uv buffer
    /////////////////////////////
    index = 0;
    CGFloat each_of_uv = 1.0f / (NUMBER_OF_POINT - 1);// [0,1]
    
    CGFloat startPosition = 1.0f - partIndex * each_of_uv;
    
    CGFloat top_v = 1.0f;
    
    //top
    for( int i  = 0 ; i < partIndex + 1; i++)
    {
        uvBuf[index++] = startPosition + i * each_of_uv;
        uvBuf[index++] = top_v;
    }
    
    for( CGFloat i  = 0 ; i  <= startPosition+0.0001f ; i += each_of_uv )
    {
        uvBuf[index++] = i;
        uvBuf[index++] = top_v;
    }
    
    
    CGFloat bottom_v = 0.0f;
    //bottom
    for( int i  = 0 ; i < partIndex + 1; i++)
    {
        uvBuf[index++] = startPosition + i * each_of_uv;
        uvBuf[index++] = bottom_v;
    }
    
    for( CGFloat i  = 0 ; i  <= startPosition+0.0001f ; i += each_of_uv )
    {
        uvBuf[index++] = i;
        uvBuf[index++] = bottom_v;
    }
    
    printf("uv index:%d -- count:%d \n" , index ,(COUNT ) * 2 );
    
    
    index = 0;
    int top_left,top_right;
    int bottom_left,bottom_right;
    
    //索引buf
    for(int i = 0 ; i < NUMBER_OF_POINT ; i++)
    {
        if(i == partIndex) continue ; // skip this
        
        top_left = i;
        top_right = top_left + 1;
        bottom_left  = top_left + NUMBER_OF_POINT + 1;
        bottom_right = top_right + NUMBER_OF_POINT + 1;
        
        index_buf[index++] = top_left;
        index_buf[index++] = top_right;
        index_buf[index++] = bottom_left;
        
        index_buf[index++] = bottom_left;
        index_buf[index++] = top_right;
        index_buf[index++] = bottom_right;
    }
    printf("index buf : %d   %d \n" , index , (NUMBER_OF_POINT - 1) * 6 );
    
        //check -----
    
        index = 0;
    
        printf("check top>>>>>>>>>>>>>>>>>>>>>> \n");
        for(int i = 0 ; i < NUMBER_OF_POINT + 1 ; i++)
        {
            printf("(%f %f %f) " , vertexBuf[index++], vertexBuf[index++], vertexBuf[index++]);
        }
        printf(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  \n");
    
    
        printf("check bottom>>>>>>>>>>>>>>>>>>>>>> \n");
        for(int i = 0 ; i < NUMBER_OF_POINT + 1 ; i++)
        {
            printf("(%f %f %f) " , vertexBuf[index++], vertexBuf[index++], vertexBuf[index++]);
        }
        printf(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  \n");
    
    
        index = 0;
        printf("uv check top>>>>>>>>>>>>>>>>>>>>>> \n");
        for(int i = 0 ; i < NUMBER_OF_POINT + 1 ; i++)
        {
            printf("(%f %f ) " , uvBuf[index++] , uvBuf[index++]);
        }
        printf(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  \n");
    
        printf("uv check bottom>>>>>>>>>>>>>>>>>>>>>> \n");
        for(int i = 0 ; i < NUMBER_OF_POINT + 1 ; i++)
        {
            printf("(%f %f) " , uvBuf[index++] , uvBuf[index++]);
        }
        printf(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  \n");
    
        index = 0;
        printf("check index buffer>>>>>>>>>>>>>>>>>>>>>> \n");
        for(int i = 0 ; i < NUMBER_OF_POINT - 1 ; i++)
        {
            printf("(%d %d %d) - (%d %d %d) \n" , index_buf[index++],index_buf[index++],index_buf[index++],index_buf[index++],index_buf[index++],index_buf[index++]);
        }
        printf("\n");
    
    
}


- (IBAction)leftMove:(id)sender
{
//    GLKView *view = (GLKView*)self.view;
    
    duplicate_location -= 1;
    if(duplicate_location < 0)
    {
        duplicate_location = NUMBER_OF_POINT   - 1;
    }
    
    [self buildModels:duplicate_location radius:_radius];
    
//    [view display];
}


-(IBAction)rightMove:(id)sender
{
    
//    GLKView *view = (GLKView*)self.view;
    
    duplicate_location += 1;
    if(duplicate_location > NUMBER_OF_POINT -1)
    {
        duplicate_location = 0;
    }
     [self buildModels:duplicate_location radius:_radius];
    
//    [view display];
}

//展开
- (IBAction)Expand:(id)sender
{
    expandIndex_ += 2;
    int maxExpandValue = (NUMBER_OF_POINT - 1) / 2 ;
    if( expandIndex_ > maxExpandValue )
    {
        expandIndex_ = (NUMBER_OF_POINT - 1)/2 ;
    }
    
    //建立顶点和纹理坐标
    [self buildModels:duplicate_location radius:_radius];
}

//收缩
- (IBAction)Shrink:(id)sender
{
    expandIndex_ -= 2;
    if(expandIndex_ < 0)
    {
        expandIndex_ = 0;
    }
    [self buildModels:duplicate_location radius:_radius];
}

@end
