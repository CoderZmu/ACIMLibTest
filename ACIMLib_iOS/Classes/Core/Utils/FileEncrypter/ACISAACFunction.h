//
//  SGISAACFunction.h
//  Sugram
//
//  Created by gnutech004 on 2017/3/23.
//  Copyright © 2017年 gossip. All rights reserved.
//

#ifndef SGISAACFunction_h
#define SGISAACFunction_h

#include <stdio.h>

#endif /* SGISAACFunction_h */

enum ciphermode {
    mEncipher, mDecipher, mNone
};

void iSeed(char *seed, int flag);

char* Vernam(char msg[],uint32_t len);

char* CaesarStr(enum ciphermode m, char *msg, char modulo, char start);

