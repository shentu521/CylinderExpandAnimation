//
//  sphereCamera.cpp
//  TestRotateMomemtum
//
//  Created by zhangkai on 2019/1/9.
//  Copyright © 2019 zhangkai. All rights reserved.
//

#include "sphereCamera.h"

const float MOMENTUM_FACTOR_DECREASE = 0.85f;
const float MOMENTUM_FACTOR_DECREASE_SHIFT = 0.9f;
const float MOMENTUM_FACTOR = 0.8f;
const float MOMENTUM_FACTOR_THRESHOLD = 0.001f;

sphereCamera::sphereCamera()
:
dragging_(false),momentum_(false),
xDragDelta_(0.f),yDragDelta_(0.f)
{
    
}

void sphereCamera::SetWH(int width, int height)
{
    window_Width_ = width;
    window_Height_ = height;
}

void sphereCamera::BeginDrag(float x, float y)
{
    dragging_ = true;
    momentum_ = false;
    
    last_down_X_ = x;
    last_down_Y_ = y;
    
    xDragDelta_ = yDragDelta_ = 0.f;
}

void sphereCamera::DragMove(float x, float y)
{
    if(!dragging_) return;
    
    xDragDelta_ = xDragDelta_ * MOMENTUM_FACTOR  + (x - last_down_X_) / window_Width_ * 360.0f;
    
    yDragDelta_ = yDragDelta_ * MOMENTUM_FACTOR + (y - last_down_Y_) / window_Height_ * 360.0f;
    
    last_down_X_ = x;
    last_down_Y_ = y;
}

void sphereCamera::GetRotateAngle(float &rotateX, float &rotateY)
{
    rotateX = xDragDelta_;
    rotateY = yDragDelta_;
}

void sphereCamera::EndDrag()
{
    dragging_ = false;
    momentum_ = true;
    momemtum_steps_ = 1.0f;
}

bool sphereCamera::Update(const double time,bool& update,bool& finished)
{
    if(momentum_)
    {
       const float MOMENTAM_UNIT = 0.0166f;
        // Activity every 16.6msec
       if(time - time_stamp_ > MOMENTAM_UNIT)
       {
          update = true;
          float momenttum_steps = momemtum_steps_;
           
           //计算衰减角度
           xDragDelta_ = xDragDelta_ * MOMENTUM_FACTOR_DECREASE;
           yDragDelta_ = yDragDelta_ * MOMENTUM_FACTOR_DECREASE;
           
          // Count steps
           momemtum_steps_ = momenttum_steps * MOMENTUM_FACTOR_DECREASE;
           if (momemtum_steps_ < MOMENTUM_FACTOR_THRESHOLD) {
               momentum_ = false;
               finished = true;
               return false;
           }
           time_stamp_ = time;
       }
    }
    else
    {
        //time_stamp_ = time;
    }
    return true;
}

sphereCamera::~sphereCamera()
{
    
}



