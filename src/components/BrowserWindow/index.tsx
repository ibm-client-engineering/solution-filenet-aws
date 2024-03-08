/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React, {type CSSProperties, type ReactNode} from 'react';

interface Props {
    children: ReactNode;
    minHeight?: number;
    url: string;
    style?: CSSProperties;
    bodyStyle?: CSSProperties;
}

export default function BrowserWindow({
                                          children,
                                          minHeight,
                                          url = 'http://localhost:3000',
                                          style,
                                          bodyStyle,
                                      }: Props): JSX.Element {
    return (
        <div style={{...style, minHeight}}>
            <div>
                <div>
                    <span/>
                    <span/>
                    <span/>
                </div>
                <div>
                    {url}
                </div>
                <div>
                    <div>
                        <span/>
                        <span/>
                        <span/>
                    </div>
                </div>
            </div>

            <div style={bodyStyle}>
                {children}
            </div>
        </div>
    );
}

// Quick and dirty component, to improve later if needed
export function IframeWindow({url}: {url: string}): JSX.Element {
    return (
        <div style={{padding: 10}}>
            <BrowserWindow
                url={url}
                bodyStyle={{padding: 0}}>
                <iframe src={url} title={url}/>
            </BrowserWindow>
        </div>
    );
}