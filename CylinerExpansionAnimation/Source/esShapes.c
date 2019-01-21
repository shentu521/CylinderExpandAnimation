// The MIT License (MIT)
//
// Copyright (c) 2013 Dan Ginsburg, Budirijanto Purnomo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

//
// Book:      OpenGL(R) ES 3.0 Programming Guide, 2nd Edition
// Authors:   Dan Ginsburg, Budirijanto Purnomo, Dave Shreiner, Aaftab Munshi
// ISBN-10:   0-321-93388-5
// ISBN-13:   978-0-321-93388-1
// Publisher: Addison-Wesley Professional
// URLs:      http://www.opengles-book.com
//            http://my.safaribooksonline.com/book/animation-and-3d/9780133440133
//
// ESShapes.c
//
//    Utility functions for generating shapes
//

///
//  Includes
//
#include "esUtil.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdio.h>
///
// Defines
//
#define ES_PI  (3.14159265f)
#define intervalY    2
#define intervalX   4

//////////////////////////////////////////////////////////////////
//
//  Private Functions
//
//



//////////////////////////////////////////////////////////////////
//
//  Public Functions
//
//






//
/// \brief Generates geometry for a sphere.  Allocates memory for the vertex data and stores
///        the results in the arrays.  Generate index list for a TRIANGLE_STRIP
/// \param numSlices The number of slices in the sphere
/// \param vertices If not NULL, will contain array of float3 positions
/// \param normals If not NULL, will contain array of float3 normals
/// \param texCoords If not NULL, will contain array of float2 texCoords
/// \param indices If not NULL, will contain the array of indices for the triangle strip
/// \return The number of indices required for rendering the buffers (the number of indices stored in the indices array
///         if it is not NULL ) as a GL_TRIANGLE_STRIP
//
int ESUTIL_API esGenSphere ( int numSlices, float radius, GLfloat **vertices, GLfloat **normals,
                             GLfloat **texCoords, GLuint **indices )
{
   int i;
   int j;
   int numParallels = numSlices / 2;
   int numVertices = ( numParallels + 1 ) * ( numSlices + 1 );
   int numIndices = numParallels * numSlices * 6;
   float angleStep = ( 2.0f * ES_PI ) / ( ( float ) numSlices );

   // Allocate memory for buffers
   if ( vertices != NULL )
   {
      *vertices = malloc ( sizeof ( GLfloat ) * 3 * numVertices );
   }

   if ( normals != NULL )
   {
      *normals = malloc ( sizeof ( GLfloat ) * 3 * numVertices );
   }

   if ( texCoords != NULL )
   {
      *texCoords = malloc ( sizeof ( GLfloat ) * 2 * numVertices );
   }

   if ( indices != NULL )
   {
      *indices = malloc ( sizeof ( GLuint ) * numIndices );
   }

   for ( i = 0; i < numParallels + 1; i++ )
   {
      for ( j = 0; j < numSlices + 1; j++ )
      {
         int vertex = ( i * ( numSlices + 1 ) + j ) * 3;

         if ( vertices )
         {
            ( *vertices ) [vertex + 0] = radius * sinf ( angleStep * ( float ) i ) *
                                         sinf ( angleStep * ( float ) j );
            ( *vertices ) [vertex + 1] = radius * cosf ( angleStep * ( float ) i );
            ( *vertices ) [vertex + 2] = radius * sinf ( angleStep * ( float ) i ) *
                                         cosf ( angleStep * ( float ) j );
         }

         if ( normals )
         {
            ( *normals ) [vertex + 0] = ( *vertices ) [vertex + 0] / radius;
            ( *normals ) [vertex + 1] = ( *vertices ) [vertex + 1] / radius;
            ( *normals ) [vertex + 2] = ( *vertices ) [vertex + 2] / radius;
         }

         if ( texCoords )
         {
            int texIndex = ( i * ( numSlices + 1 ) + j ) * 2;
            ( *texCoords ) [texIndex + 0] = ( float ) j / ( float ) numSlices;
            ( *texCoords ) [texIndex + 1] = ( 1.0f - ( float ) i ) / ( float ) ( numParallels - 1 );
         }
      }
   }

   // Generate the indices
   if ( indices != NULL )
   {
      GLuint *indexBuf = ( *indices );

      for ( i = 0; i < numParallels ; i++ )
      {
         for ( j = 0; j < numSlices; j++ )
         {
            *indexBuf++  = i * ( numSlices + 1 ) + j;
            *indexBuf++ = ( i + 1 ) * ( numSlices + 1 ) + j;
            *indexBuf++ = ( i + 1 ) * ( numSlices + 1 ) + ( j + 1 );

            *indexBuf++ = i * ( numSlices + 1 ) + j;
            *indexBuf++ = ( i + 1 ) * ( numSlices + 1 ) + ( j + 1 );
            *indexBuf++ = i * ( numSlices + 1 ) + ( j + 1 );
         }
      }
   }

   return numIndices;
}

//绘制援助图，这次我们采用的是三角形的绘制方式
void ESUTIL_API esGenCylinder2 ( float radius, GLfloat **_vertices, GLfloat **normals,
                              GLfloat **texCoords, GLuint **indices , GLfloat ** colors)
{
    
    //绘制一个正方形
    
}



//绘制圆柱体
int ESUTIL_API esGenCylinder ( float radius, GLfloat **vertices, GLfloat **normals,
                              GLfloat **texCoords, GLuint **indices , GLfloat ** colors)
{
    int YAngle = 0;
    int XAngle = 0;
    
    int i = 0;
    
    int rowtick = 0;
    int coltick = 0;
    
    double perRadius = M_PI / 180.0; //角度转弧度
    (*vertices) = malloc((180 / intervalY) * (360 / (intervalX)) * 6 * 5 * sizeof(GLfloat));
    
    for (YAngle = 0, rowtick = 0; YAngle < 180; YAngle += intervalY, rowtick++) //将Y轴切割为90份
    {
        
        float Y0 = -cosf((float)YAngle * perRadius);
        float Y1 = -cosf((float)(YAngle + intervalY) * perRadius);
        
        //通过线性插值计算得出----
        //        float R0 = sinf((float)YAngle*perRadius); //sin0-180 为0-1永远是正直的
        //        float R1 = sinf((float)(YAngle + intervalY) * perRadius);
        
        float R0 = 1.0f;
        float R1 = 1.0f;
        
       
        
        //等比例计算  -- 如果是bmp的位图rgb,那么就不需要1.0 -
        float V0 = 1.0 - (float)YAngle / 180.0;
        float V1 = 1.0 - (float)(YAngle + intervalY) / 180.0;
        
        for (XAngle = 0, coltick = 0; XAngle < 360; XAngle += intervalX, coltick++)
        {
            // 第1个顶点
            float a1x = R0 * cosf((float)XAngle * perRadius);
            float a1y = Y0;
            float a1z = -R0 * sinf((float)XAngle * perRadius);
            
            float a1u = 0;
            a1u = 1.0 - (float)XAngle / 360.0;
            float a1v = V0;
            
            //第2个顶点
            float a2x = R1 * cosf((float)XAngle * perRadius);
            float a2y = Y1;
            float a2z = -R1 * sinf((float)XAngle * perRadius);
            
            float a2u = 0;
            a2u = 1.0 - (float)XAngle / 360.0;
            float a2v = V1;
            
            //第3个顶点
            float a3x = R1 * cosf((float)(XAngle + intervalX) * perRadius);
            float a3y = Y1;
            float a3z = -R1 * sinf((float)(XAngle + intervalX) * perRadius);
            
            float a3u = 0.0f;
            a3u = 1.0 - (float)(XAngle + intervalX) / 360.0;
            float a3v = V1;
            
            //第4个顶点
            float a4x = R0 * cosf((float)(XAngle + intervalX) * perRadius);
            float a4y = Y0;
            float a4z = -R0 * sinf((float)(XAngle + intervalX) * perRadius);
            
            float a4u = 0.0f;
            a4u = 1.0 - (float)(XAngle + intervalX) / 360.0;
            float a4v = V0;
            
            //构建第一个三角形
            (*vertices)[i++] = a1x; (*vertices)[i++] = a1y; (*vertices)[i++] = a1z;  (*vertices)[i++] = a1u; (*vertices)[i++] = a1v;
            (*vertices)[i++] = a2x; (*vertices)[i++] = a2y; (*vertices)[i++] = a2z;  (*vertices)[i++] = a2u; (*vertices)[i++] = a2v;
            (*vertices)[i++] = a3x; (*vertices)[i++] = a3y; (*vertices)[i++] = a3z;  (*vertices)[i++] = a3u; (*vertices)[i++] = a3v;
            
            //构建第二个三角形
            (*vertices)[i++] = a3x; (*vertices)[i++] = a3y; (*vertices)[i++] = a3z;  (*vertices)[i++] = a3u; (*vertices)[i++] = a3v;
            (*vertices)[i++] = a4x; (*vertices)[i++] = a4y; (*vertices)[i++] = a4z;  (*vertices)[i++] = a4u; (*vertices)[i++] = a4v;
            (*vertices)[i++] = a1x; (*vertices)[i++] = a1y; (*vertices)[i++] = a1z;  (*vertices)[i++] = a1u; (*vertices)[i++] = a1v;
            
        }
    }
    
    //球体的绘制
    
//    int YAngle = 0;
//    int XAngle = 0;
//
//    int i = 0;
//
//    int rowtick = 0;
//    int coltick = 0;
//
//    (*vertices) = malloc((180 / intervalY) * (360 / (intervalX)) * 6 * 5 * sizeof(GLfloat));
//
//    double perRadius = M_PI / 180.0; //Ω«∂»◊™ª°∂»
//
//    for (YAngle = 0, rowtick = 0; YAngle < 180; YAngle += intervalY, rowtick++) //Ω´Y÷·«–∏ÓŒ™90∑›
//    {
//
//        float Y0 = -cosf((float)YAngle * perRadius);
//        float Y1 = -cosf((float)(YAngle + intervalY) * perRadius);
//
//        //Õ®π˝œﬂ–‘≤Â÷µº∆À„µ√≥ˆ----
////        float R0 = sinf((float)YAngle*perRadius); //sin0-180 Œ™0-1”¿‘∂ «’˝÷±µƒ
////        float R1 = sinf((float)(YAngle + intervalY) * perRadius);
//
//        float R0 = 1.0f; //sin0-180 Œ™0-1”¿‘∂ «’˝÷±µƒ
//        float R1 = 1.0f;
//
//        //µ»±»¿˝º∆À„  -- »Áπ˚ «bmpµƒŒªÕºrgb,ƒ«√¥æÕ≤ª–Ë“™1.0 -
//        float V0 = 1.0 - (float)YAngle / 180.0;
//        float V1 = 1.0 - (float)(YAngle + intervalY) / 180.0;
//
//        for (XAngle = 0, coltick = 0; XAngle < 360; XAngle += intervalX, coltick++)
//        {
//            // µ⁄1∏ˆ∂•µ„
//            float a1x = R0 * cosf((float)XAngle * perRadius);
//            float a1y = Y0;
//            float a1z = -R0 * sinf((float)XAngle * perRadius);
//
//            float a1u = 0;
//            a1u = 1.0 - (float)XAngle / 360.0;
//            float a1v = V0;
//
//            //µ⁄2∏ˆ∂•µ„
//            float a2x = R1 * cosf((float)XAngle * perRadius);
//            float a2y = Y1;
//            float a2z = -R1 * sinf((float)XAngle * perRadius);
//
//            float a2u = 0;
//            a2u = 1.0 - (float)XAngle / 360.0;
//            float a2v = V1;
//
//            //µ⁄3∏ˆ∂•µ„
//            float a3x = R1 * cosf((float)(XAngle + intervalX) * perRadius);
//            float a3y = Y1;
//            float a3z = -R1 * sinf((float)(XAngle + intervalX) * perRadius);
//
//            float a3u = 0.0f;
//            a3u = 1.0 - (float)(XAngle + intervalX) / 360.0;
//            float a3v = V1;
//
//            //µ⁄4∏ˆ∂•µ„
//            float a4x = R0 * cosf((float)(XAngle + intervalX) * perRadius);
//            float a4y = Y0;
//            float a4z = -R0 * sinf((float)(XAngle + intervalX) * perRadius);
//
//            float a4u = 0.0f;
//            a4u = 1.0 - (float)(XAngle + intervalX) / 360.0;
//            float a4v = V0;
//
//            //ππΩ®µ⁄“ª∏ˆ»˝Ω«–Œ
//            (*vertices)[i++] = a1x; (*vertices)[i++] = a1y; (*vertices)[i++] = a1z;  (*vertices)[i++] = a1u; (*vertices)[i++] = a1v;
//            (*vertices)[i++] = a2x; (*vertices)[i++] = a2y; (*vertices)[i++] = a2z;  (*vertices)[i++] = a2u; (*vertices)[i++] = a2v;
//            (*vertices)[i++] = a3x; (*vertices)[i++] = a3y; (*vertices)[i++] = a3z;  (*vertices)[i++] = a3u; (*vertices)[i++] = a3v;
//
//            //ππΩ®µ⁄∂˛∏ˆ»˝Ω«–Œ
//            (*vertices)[i++] = a3x; (*vertices)[i++] = a3y; (*vertices)[i++] = a3z;  (*vertices)[i++] = a3u; (*vertices)[i++] = a3v;
//            (*vertices)[i++] = a4x; (*vertices)[i++] = a4y; (*vertices)[i++] = a4z;  (*vertices)[i++] = a4u; (*vertices)[i++] = a4v;
//            (*vertices)[i++] = a1x; (*vertices)[i++] = a1y; (*vertices)[i++] = a1z;  (*vertices)[i++] = a1u; (*vertices)[i++] = a1v;
//
//            printf("u:%f v:%f \n" , a1u,a1v);
//        }
//    }
    
    
//    //直接以三角形的方式走

    //circle -- [ 0  360 ]
//    const int angle_step = 18;
//
//    int numberCountOfX   = 360 / angle_step ; //圆上有21个点，坐标标号[0,20],但是最后我只会走到19就不走了(由于绘制三角形的属性所决定的)
//    int numberCountOfY = (int)( 2 / 0.1f ) ;
//    const float x_step = 1.0f / numberCountOfX ;
//    const float y_step = 1.0f / numberCountOfY ;
//
//
//    //圆柱体的高度从 [-1 0.9]
//    *vertices = malloc( numberCountOfX *  numberCountOfY * 6 * 5 * sizeof(GLfloat) ); // 2个三角形，6个点，每个点(x,y,z / u,v)
//
//    float y = 0;
//    int count = 0;
//    int count1 = 0;
//
//    for(float i  = -1.0f ;  i < 1.0f ; i += 0.1f )
//    {
//        float x1,x2,x3,x4;
//        float z1,z2,z3,z4;
//        float y1 = i;
//        float y2 = i + 0.1;
//        float y3 = i;
//        float y4 = i + 0.1;
//        float u1,u2,u3,u4;
//        float v1,v2,v3,v4;
//
//        // 4  2
//        // 3  1
//        float angle ;
//
//        //绘制顺序为: (1 2 3) / (2 4 3) 逆时针顺序
//        for( int j = 0 ; j <  ( numberCountOfX)  ; j++ ) //从0走到71
//        {
//            angle = j * angle_step;
//
//            //第一个点
//            x1 = radius * cosf(angle * M_PI / 180.0f);
//            z1 = radius * sinf(angle * M_PI / 180.0f);
//            u1 =  j * x_step;
//            v1 =  count * y_step;
//
//
//            //第二个点
//            x2 = x1;
//            z2 = z1;
//            u2 = u1;
//            v2 = (count+1) * y_step;
//
//            //第三个点
//            x3 = radius * cosf( (j+1) * angle_step * M_PI / 180.0f);
//            z3 = radius * sinf( (j+1) * angle_step * M_PI / 180.0f);
//            u3 = (j+1) * x_step;
//            v3 = v1;
//
//            //第四个点
//            x4 = x3;
//            z4 = z3;
//            u4 = u3;
//            v4 = v2;
//
//            printf("x1:%f y1:%f z1:%f \n" , x1,y1,z1);
//            printf("x2:%f y2:%f z2:%f \n" , x2,y2,z2);
//            printf("x3:%f y3:%f z3:%f \n" , x3,y3,z3);
//
//
//            //配置: (1 2 3) / (2 4 3)
//            (*vertices)[count1++] = x1;
//            (*vertices)[count1++] = y1;
//            (*vertices)[count1++] = z1;
//            (*vertices)[count1++] = u1;
//            (*vertices)[count1++] = v1;
//
//            (*vertices)[count1++] = x2;
//            (*vertices)[count1++] = y2;
//            (*vertices)[count1++] = z2;
//            (*vertices)[count1++] = u2;
//            (*vertices)[count1++] = v2;
//
//            (*vertices)[count1++] = x3;
//            (*vertices)[count1++] = y3;
//            (*vertices)[count1++] = z3;
//            (*vertices)[count1++] = u3;
//            (*vertices)[count1++] = v3;
//
//            (*vertices)[count1++] = x2;
//            (*vertices)[count1++] = y2;
//            (*vertices)[count1++] = z2;
//            (*vertices)[count1++] = u2;
//            (*vertices)[count1++] = v2;
//
//            (*vertices)[count1++] = x4;
//            (*vertices)[count1++] = y4;
//            (*vertices)[count1++] = z4;
//            (*vertices)[count1++] = u4;
//            (*vertices)[count1++] = v4;
//
//            (*vertices)[count1++] = x3;
//            (*vertices)[count1++] = y3;
//            (*vertices)[count1++] = z3;
//            (*vertices)[count1++] = u3;
//            (*vertices)[count1++] = v3;
//        }
//
//        count ++;
//    }
//    printf("count1:%d -- %d" , count1 ,numberCountOfX *  numberCountOfY * 6 * 5 );
    
    return (180 / intervalY) * (360 / (intervalX)) * 6 * 5 ;
    
    //这种走索引的方式太繁琐了，开始走三角形的方式走
//    const float ANGLE_STEP  = 5;//每次递增5度
//    const float Y_STEP  = 0.1f;  //垂直高度从-10到10，每次+1
//
//    int numberCountOfX   = 360 / ANGLE_STEP + 1;//x轴上一共有多少个点
//    int numberCountOfY   = 2 / Y_STEP + 1;//一共有这么多行
//
//    int numVertices = numberCountOfX * numberCountOfY ;//一共有这么多个点
//
//    *colors = malloc(  sizeof(float) * 2 * numVertices );
//    *vertices = malloc( sizeof(float) * 3 * numVertices);
//
//    //指定顶点坐标
//    int count0 = 0;
//
//    for(float h = -1.0f ; h < 1.0f + 0.0000001f ; h += Y_STEP)
//    {
//        //y是保持不变的f
//        float y = h ;
//
//        //x,z坐标是变动的 -- 主要要把角度转为弧度
//        for(int angle = 0 ; angle <= 360 ; angle += ANGLE_STEP )
//        {
//            float z = radius * cosf(angle * ES_PI / 180.0f);
//            float x = radius * sinf(angle * ES_PI / 180.0f );
//
//            (*vertices)[count0++] = x;
//            (*vertices)[count0++] = y ;
//            (*vertices)[count0++] = z;
//        }
//    }
//
//    printf("count0:%d -- total:%d \n" , count0  , numberCountOfX * numberCountOfY);
//
//    //一共有numberCountOfY行,指定索引时，我们只需要制定到numberCountOfY-1行就行.
//    *indices = malloc( (numberCountOfY-1) * (numberCountOfX-1) * 6 * sizeof(GL_UNSIGNED_INT) );
//    int count = 0;
//
//    for(int i = 0 ; i < numberCountOfY - 1 ; i++)
//    {
//        int start = i * numberCountOfX;
//        for(int j = 0 ; j < (numberCountOfX-1) ; j++ )
//        {
//            //j每向前走一步,都会产生一个正方向，我们是按逆时针的顺序走的
//            (*indices)[count++] = start + j;
//            (*indices)[count++] = start + numberCountOfX + j;
//            (*indices)[count++] = start + j + 1;
//
//            (*indices)[count++] = start + j + 1;
//            (*indices)[count++] = start + numberCountOfX + j;
//            (*indices)[count++] = start + j + numberCountOfX + 1;
//        }
//    }
//    printf(" count:%d - check size:%d \n " , count ,(numberCountOfY-1) * (numberCountOfX-1) * 6 );
//
//    //崩溃的原因是:
//    //
//
//    //设置纹理坐标
//    float ystep = 1.0f / (numberCountOfY-1) ;
//    float xstep = 1.0f / (numberCountOfX-1) ;
//
//    count = 0;
//
//    float y_position = 0.0f;
//    for(int i = 0 ; i < numberCountOfY ; i++)
//    {
//        float x_position = 0.0f;
//        for(int j = 0 ; j < numberCountOfX ; j++)
//        {
//            (*colors)[count++] = x_position;
//            (*colors)[count++] = y_position;
//
//            x_position += xstep;
//        }
//        y_position += ystep;
//    }
//
//    return (numberCountOfY-1) * (numberCountOfX-1) * 6;
}


//
/// \brief Generates geometry for a cube.  Allocates memory for the vertex data and stores
///        the results in the arrays.  Generate index list for a TRIANGLES
/// \param scale The size of the cube, use 1.0 for a unit cube.
/// \param vertices If not NULL, will contain array of float3 positions
/// \param normals If not NULL, will contain array of float3 normals
/// \param texCoords If not NULL, will contain array of float2 texCoords
/// \param indices If not NULL, will contain the array of indices for the triangle strip
/// \return The number of indices required for rendering the buffers (the number of indices stored in the indices array
///         if it is not NULL ) as a GL_TRIANGLE_STRIP
//
int ESUTIL_API esGenCube ( float scale, GLfloat **vertices, GLfloat **normals,
                           GLfloat **texCoords, GLuint **indices )
{
   int i;
   int numVertices = 24;
   int numIndices = 36;

   GLfloat cubeVerts[] =
   {
      -0.5f, -0.5f, -0.5f,
      -0.5f, -0.5f,  0.5f,
      0.5f, -0.5f,  0.5f,
      0.5f, -0.5f, -0.5f,
      -0.5f,  0.5f, -0.5f,
      -0.5f,  0.5f,  0.5f,
      0.5f,  0.5f,  0.5f,
      0.5f,  0.5f, -0.5f,
      -0.5f, -0.5f, -0.5f,
      -0.5f,  0.5f, -0.5f,
      0.5f,  0.5f, -0.5f,
      0.5f, -0.5f, -0.5f,
      -0.5f, -0.5f, 0.5f,
      -0.5f,  0.5f, 0.5f,
      0.5f,  0.5f, 0.5f,
      0.5f, -0.5f, 0.5f,
      -0.5f, -0.5f, -0.5f,
      -0.5f, -0.5f,  0.5f,
      -0.5f,  0.5f,  0.5f,
      -0.5f,  0.5f, -0.5f,
      0.5f, -0.5f, -0.5f,
      0.5f, -0.5f,  0.5f,
      0.5f,  0.5f,  0.5f,
      0.5f,  0.5f, -0.5f,
   };

   GLfloat cubeNormals[] =
   {
      0.0f, -1.0f, 0.0f,
      0.0f, -1.0f, 0.0f,
      0.0f, -1.0f, 0.0f,
      0.0f, -1.0f, 0.0f,
      0.0f, 1.0f, 0.0f,
      0.0f, 1.0f, 0.0f,
      0.0f, 1.0f, 0.0f,
      0.0f, 1.0f, 0.0f,
      0.0f, 0.0f, -1.0f,
      0.0f, 0.0f, -1.0f,
      0.0f, 0.0f, -1.0f,
      0.0f, 0.0f, -1.0f,
      0.0f, 0.0f, 1.0f,
      0.0f, 0.0f, 1.0f,
      0.0f, 0.0f, 1.0f,
      0.0f, 0.0f, 1.0f,
      -1.0f, 0.0f, 0.0f,
      -1.0f, 0.0f, 0.0f,
      -1.0f, 0.0f, 0.0f,
      -1.0f, 0.0f, 0.0f,
      1.0f, 0.0f, 0.0f,
      1.0f, 0.0f, 0.0f,
      1.0f, 0.0f, 0.0f,
      1.0f, 0.0f, 0.0f,
   };

   GLfloat cubeTex[] =
   {
      0.0f, 0.0f,
      0.0f, 1.0f,
      1.0f, 1.0f,
      1.0f, 0.0f,
      1.0f, 0.0f,
      1.0f, 1.0f,
      0.0f, 1.0f,
      0.0f, 0.0f,
      0.0f, 0.0f,
      0.0f, 1.0f,
      1.0f, 1.0f,
      1.0f, 0.0f,
      0.0f, 0.0f,
      0.0f, 1.0f,
      1.0f, 1.0f,
      1.0f, 0.0f,
      0.0f, 0.0f,
      0.0f, 1.0f,
      1.0f, 1.0f,
      1.0f, 0.0f,
      0.0f, 0.0f,
      0.0f, 1.0f,
      1.0f, 1.0f,
      1.0f, 0.0f,
   };

   // Allocate memory for buffers
   if ( vertices != NULL )
   {
      *vertices = malloc ( sizeof ( GLfloat ) * 3 * numVertices );
      memcpy ( *vertices, cubeVerts, sizeof ( cubeVerts ) );

      for ( i = 0; i < numVertices * 3; i++ )
      {
         ( *vertices ) [i] *= scale;
      }
   }

   if ( normals != NULL )
   {
      *normals = malloc ( sizeof ( GLfloat ) * 3 * numVertices );
      memcpy ( *normals, cubeNormals, sizeof ( cubeNormals ) );
   }

   if ( texCoords != NULL )
   {
      *texCoords = malloc ( sizeof ( GLfloat ) * 2 * numVertices );
      memcpy ( *texCoords, cubeTex, sizeof ( cubeTex ) ) ;
   }


   // Generate the indices
   if ( indices != NULL )
   {
      GLuint cubeIndices[] =
      {
         0, 2, 1,
         0, 3, 2,
         4, 5, 6,
         4, 6, 7,
         8, 9, 10,
         8, 10, 11,
         12, 15, 14,
         12, 14, 13,
         16, 17, 18,
         16, 18, 19,
         20, 23, 22,
         20, 22, 21
      };

      *indices = malloc ( sizeof ( GLuint ) * numIndices );
      memcpy ( *indices, cubeIndices, sizeof ( cubeIndices ) );
   }

   return numIndices;
}

//
/// \brief Generates a square grid consisting of triangles.  Allocates memory for the vertex data and stores
///        the results in the arrays.  Generate index list as TRIANGLES.
/// \param size create a grid of size by size (number of triangles = (size-1)*(size-1)*2)
/// \param vertices If not NULL, will contain array of float3 positions
/// \param indices If not NULL, will contain the array of indices for the triangle strip
/// \return The number of indices required for rendering the buffers (the number of indices stored in the indices array
///         if it is not NULL ) as a GL_TRIANGLES
//
int ESUTIL_API esGenSquareGrid ( int size, GLfloat **vertices, GLuint **indices )
{
   int i, j;
   int numIndices = ( size - 1 ) * ( size - 1 ) * 2 * 3;

   // Allocate memory for buffers
   if ( vertices != NULL )
   {
      int numVertices = size * size;
      float stepSize = ( float ) size - 1;
      *vertices = malloc ( sizeof ( GLfloat ) * 3 * numVertices );

      for ( i = 0; i < size; ++i ) // row
      {
         for ( j = 0; j < size; ++j ) // column
         {
            ( *vertices ) [ 3 * ( j + i * size )     ] = i / stepSize;
            ( *vertices ) [ 3 * ( j + i * size ) + 1 ] = j / stepSize;
            ( *vertices ) [ 3 * ( j + i * size ) + 2 ] = 0.0f;
         }
      }
   }

   // Generate the indices
   if ( indices != NULL )
   {
      *indices = malloc ( sizeof ( GLuint ) * numIndices );

      for ( i = 0; i < size - 1; ++i )
      {
         for ( j = 0; j < size - 1; ++j )
         {
            // two triangles per quad
            ( *indices ) [ 6 * ( j + i * ( size - 1 ) )     ] = j + ( i )   * ( size )    ;
            ( *indices ) [ 6 * ( j + i * ( size - 1 ) ) + 1 ] = j + ( i )   * ( size ) + 1;
            ( *indices ) [ 6 * ( j + i * ( size - 1 ) ) + 2 ] = j + ( i + 1 ) * ( size ) + 1;

            ( *indices ) [ 6 * ( j + i * ( size - 1 ) ) + 3 ] = j + ( i )   * ( size )    ;
            ( *indices ) [ 6 * ( j + i * ( size - 1 ) ) + 4 ] = j + ( i + 1 ) * ( size ) + 1;
            ( *indices ) [ 6 * ( j + i * ( size - 1 ) ) + 5 ] = j + ( i + 1 ) * ( size )    ;
         }
      }
   }

   return numIndices;
}
