//
//  ACNetErrorConverter.m
//  ACIMLib
//
//  Created by 子木 on 2022/7/22.
//

#import "ACNetErrorConverter.h"

@implementation ACNetErrorConverter


+ (ACErrorCode)toAcErrorCodeEnumProperty:(NSInteger)respCode {
    ACErrorCode retValue;
    switch (respCode) {
        case 0:
            retValue = AC_SUCCESS;
            break;
        case 0x3e9: // 超时
            retValue = AC_MSG_RESPONSE_TIMEOUT;
            break;
        case 0x3ea: // 连接关闭
            retValue = AC_CHANNEL_INVALID;
            break;
        case 22406: // 群成员不存在
        case 0x60020001: // 不在群组
            retValue = NOT_IN_GROUP;
            break;
        case 0x60010003: // 消息大小超限
            retValue = AC_MSG_SIZE_OUT_OF_LIMIT;
            break;
        case 0x60010004: // 拒收
            retValue = REJECTED_BY_BLACKLIST;
            break;
        case 0x00000003: // 参数非法
            retValue = INVALID_PARAMETER;
            break;
        case FORBIDDEN_IN_GROUP: // 禁言
        case REJECTED_BY_BLACKLIST: // 被对方拉黑
        case SEND_MSG_FREQUENCY_OVERRUN: // 超频
        case AC_MSG_BLOCKED_SENSITIVE_WORD: // 包含敏感词
        case AC_MSG_REPLACED_SENSITIVE_WORD: // 敏感词被替换
            retValue = respCode;
            break;
        default:
            retValue = ERRORCODE_UNKNOWN;
            break;
    }
    
    return retValue;
}
@end
