//
//  sphereCamera.hpp
//  TestRotateMomemtum
//
//  Created by zhangkai on 2019/1/9.
//  Copyright © 2019 zhangkai. All rights reserved.
//

#ifndef sphereCamera_hpp
#define sphereCamera_hpp

#include <stdio.h>

class sphereCamera
{
public:
    sphereCamera();
    ~sphereCamera();
    
    
public:
    void BeginDrag(float x,float y);
    void DragMove(float x,float y);
    void EndDrag();
    
    void SetWH(int width,int height);
    bool Update(const double time,bool& update,bool& finished);
    void GetRotateAngle(float &rotateX,float &rotateY);
    
private:
    int window_Width_;
    int window_Height_;
    
    float last_down_X_;
    float last_down_Y_;
    float now_down_X_;
    float now_down_Y_;
    
    float xDragDelta_;
    float yDragDelta_;
    
    float momemtum_steps_;
    
    bool dragging_;
    bool momentum_;
    double time_stamp_;
    
};

#endif /* sphereCamera_hpp */
