//
//  apdu.h
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/9/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

#ifndef apdu_h
#define apdu_h

typedef struct {
    uint8_t cla;
    uint8_t ins;
    uint8_t p1;
    uint8_t p2;
    uint8_t lc;
} APDU_COMMAND_HEADER;

typedef struct {
    uint8_t cla;
    uint8_t ins;
    uint8_t p1;
    uint8_t p2;
    uint8_t lc[3];
} EXTENDED_APDU_COMMAND_HEADER;

#endif /* apdu_h */
