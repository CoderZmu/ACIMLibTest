//
//  ACSocketHeader.h
//  Pods
//
//  Created by 子木 on 2022/6/9.
//

#ifndef ACSocketHeader_h
#define ACSocketHeader_h

#define ACCommand_HandShake 0x10001003
#define ACCommand_Comfirm_HandShake 0x10001004
#define ACCommand_Heartbeat 0x10001001
#define ACCommand_Auth 0x30018024
#define ACCommand_UploadAPNsToken 0x3011100D
#define ACCommand_Logout 0x30011004

/* 协议起始标识 结束标识 */
#define ACMessage_PROTOCOL_START_FLAG       0X43
#define ACMessage_Response_PROTOCOL_START_FLAG   0X53 
#define ACMessage_PROTOCOL_END_FLAG         0X00

//消息协议包数据结构
typedef struct
{
    uint8_t         startflag;                  //起始标志      0x43
    uint8_t         padding;                    //padding      0xFF
    uint32_t        body_length;                //数据长度
    uint32_t        commandId;                  //唯一ID
} ACMessage_Protocol_Head_T;

typedef struct{
    ACMessage_Protocol_Head_T*   head;
    uint8_t                *body;         //包体
    uint8_t                endflag;       //结束标志      0x00
}ACMessage_Protocol_Packet_T;

typedef void (^ACSocketSuccessBlock)(NSData *response);
typedef void (^ACSocketFailureBlock)(NSError *error, NSInteger code);

#endif /* ACSocketHeader_h */
