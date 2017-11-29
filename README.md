# ArcFace
如何使用？
1、前往官网申请appid和sdkkey, 修改 ArcFace\ArcFace\AFVideoProcessor.mm 下面的对应的定义值
#define AFR_DEMO_APP_ID                       ""
#define AFR_DEMO_SDK_FR_KEY                   ""
#define AFR_DEMO_SDK_FT_KEY                   ""
#define AFR_DEMO_SDK_FD_KEY                   ""
#define AFR_DEMO_SDK_AGE_KEY                  ""
#define AFR_DEMO_SDK_GENDER_KEY               ""
2、下载SDK包，解压所有SDK包中的文件到工程目录下的相关子目录下，其中相同的底层库只需一个
3、Xcode打开ArcFace.xcworkspace编译运行即可在iOS8.0以上的iPhone上运行
