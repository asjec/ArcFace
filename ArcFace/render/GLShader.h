//
//  GLShader.h
//  GPUEffect
//
//  Created by jhzheng on 14-12-3.
//  Copyright (c) 2014妤�锟介��锟� GPUEffect. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <AVFoundation/AVFoundation.h>

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

// back ground nv12
NSString *const VertexShaderBackgroundString = SHADER_STRING
(
    attribute vec4 a_position;
    attribute vec2 a_texCoord;
    varying highp vec2 v_texCoord;

    void main()
    {
        gl_Position = a_position;
        v_texCoord = a_texCoord;
    }
);

NSString *const FragmentShaderBackgroundString = SHADER_STRING
(
    precision highp float;
    uniform sampler2D y_texture;
    uniform sampler2D uv_texture;
    uniform bool roiEnable;
    uniform vec4 roi;
    uniform vec4 lineColor;
    uniform float lineWidth;
    varying highp vec2 v_texCoord;
    void main()
    {
        mediump vec3 yuv;
        highp vec3 rgb;
        yuv.x = texture2D(y_texture, v_texCoord).r;
        yuv.y = texture2D(uv_texture, v_texCoord).r-0.5;
        yuv.z = texture2D(uv_texture, v_texCoord).a-0.5;
        rgb = mat3(      1,       1,       1,
                   0, -0.344, 1.770,
                   1.403, -0.714,       0) * yuv;

        // roi
        if (roiEnable && (((abs(v_texCoord.x - roi.x) < lineWidth || abs(v_texCoord.x - roi.z) < lineWidth ) && (v_texCoord.y >= roi.y && v_texCoord.y <= roi.w))
            || ((abs(v_texCoord.y - roi.y) < lineWidth || abs(v_texCoord.y - roi.w) < lineWidth ) && (v_texCoord.x >= roi.x && v_texCoord.x <= roi.z)))
            )
        {
            gl_FragColor = lineColor;
        }
        else
        {
            gl_FragColor = vec4(rgb, 1);
        }
        
    }
);

// back ground rgba
NSString *const VertexShaderBackground_RGBA32String = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 varying vec2 textureCoordinate;
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
 }
 );

NSString *const FragmentShaderBackground_RGBA32String = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform int bgraFlag;
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     if(bgraFlag != 0)
         gl_FragColor = vec4(textureColor.b,textureColor.g, textureColor.r, textureColor.a);
     else
         gl_FragColor = vec4(textureColor.r,textureColor.g, textureColor.b, textureColor.a);
 }
 );
