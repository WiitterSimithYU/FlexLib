/**
 * Copyright (c) 2017-present, zhenglibao, Inc.
 * email: 798393829@qq.com
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */


#import "FlexNode.h"
#import "YogaKit/UIView+Yoga.h"
#import "YogaKit/YGLayout.h"
#import "GDataXMLNode.h"
#import "FlexStyleMgr.h"
#import "FlexUtils.h"
#import "FlexRootView.h"
#import "FlexModalView.h"
#import "ViewExt/UIView+Flex.h"

#define VIEWCLSNAME     @"viewClsName"
#define NAME            @"name"
#define ONPRESS         @"onPress"
#define LAYOUTPARAM     @"layoutParam"
#define VIEWATTRS       @"viewAttrs"
#define CHILDREN        @"children"

#pragma mark - Name values

NSData* loadFromNetwork(NSString* resName);
NSData* loadFromFile(NSString* resName);

static FlexLoadFunc gLoadFunc = loadFromFile;

#ifdef DEBUG
static BOOL gbUserCache = NO;
#else
static BOOL gbUserCache = YES;
#endif

static NameValue _direction[] =
{{"inherit", YGDirectionInherit},
 {"ltr", YGDirectionLTR},
 {"rtl", YGDirectionRTL},
};
static NameValue _flexDirection[] =
{   {"col", YGFlexDirectionColumn},
    {"col-reverse", YGFlexDirectionColumnReverse},
    {"row", YGFlexDirectionRow},
    {"row-reverse", YGFlexDirectionRowReverse},
};
static NameValue _justify[] =
{   {"flex-start", YGJustifyFlexStart},
    {"center", YGJustifyCenter},
    {"flex-end", YGJustifyFlexEnd},
    {"space-between", YGJustifySpaceBetween},
    {"space-around", YGJustifySpaceAround},
};
static NameValue _align[] =
{   {"auto", YGAlignAuto},
    {"flex-start", YGAlignFlexStart},
    {"center", YGAlignCenter},
    {"flex-end", YGAlignFlexEnd},
    {"stretch", YGAlignStretch},
    {"baseline", YGAlignBaseline},
    {"space-between", YGAlignSpaceBetween},
    {"space-around", YGAlignSpaceAround},
};
static NameValue _positionType[] =
{{"relative", YGPositionTypeRelative},
    {"absolute", YGPositionTypeAbsolute},
};

static NameValue _wrap[] =
{{"no-wrap", YGWrapNoWrap},
    {"wrap", YGWrapWrap},
    {"wrap-reverse", YGWrapWrapReverse},
};
static NameValue _overflow[] =
{{"visible", YGOverflowVisible},
    {"hidden", YGOverflowHidden},
    {"scroll", YGOverflowScroll},
};
static NameValue _display[] =
{{"flex", YGDisplayFlex},
    {"none", YGDisplayNone},
};


static YGValue String2YGValue(const char* s)
{
    int len = (int) strlen(s) ;
    if(len==0||len>100){
        return YGPointValue(0);
    }
    if( s[len-1]=='%' ){
        char dest[100];
        strncpy(dest, s, len-1);
        return YGPercentValue(atof(dest));
    }
    return YGPointValue(atof(s));
}

void FlexSetViewAttr(UIView* view,
                     NSString* attrName,
                     NSString* attrValue)
{
    NSString* methodDesc = [NSString stringWithFormat:@"setFlex%@:",attrName];
    
    SEL sel = NSSelectorFromString(methodDesc) ;
    if(sel == nil)
    {
        NSLog(@"Flexbox: %@ no method %@",[view class],methodDesc);
        return ;
    }
    
    // avoid performSelector, because maybe blocked by Apple.
    
    NSMethodSignature* sig = [[view class] instanceMethodSignatureForSelector:sel];
    if(sig == nil)
    {
        NSLog(@"Flexbox: %@ no method %@",[view class],methodDesc);
        return ;
    }
    
    @try{
        
        NSInvocation* inv = [NSInvocation invocationWithMethodSignature:sig] ;
        [inv setTarget:view];
        [inv setSelector:sel];
        [inv setArgument:&attrValue atIndex:2];
        
        [inv invoke];
    }@catch(NSException* e){
        NSLog(@"Flexbox: %@ called failed.",methodDesc);
    }
}

static void ApplyLayoutParam(YGLayout* layout,
                             NSString* key,
                             NSString* value)
{
    const char* k = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char* v = [value cStringUsingEncoding:NSASCIIStringEncoding];
 
#define SETENUMVALUE(item,table,type)      \
if(strcmp(k,#item)==0)                \
{                                        \
layout.item=(type)String2Int(v,table,sizeof(table)/sizeof(NameValue));                  \
return;                                  \
}                                        \

#define SETYGVALUE(item)       \
if(strcmp(k,#item)==0)          \
{                               \
layout.item=String2YGValue(v);  \
return;                         \
}                               \

#define SETNUMVALUE(item)       \
if(strcmp(k,#item)==0)          \
{                               \
layout.item=atof(v);            \
return;                         \
}

SETENUMVALUE(direction,_direction,YGDirection);
SETENUMVALUE(flexDirection,_flexDirection,YGFlexDirection);
SETENUMVALUE(justifyContent,_justify,YGJustify);
SETENUMVALUE(alignContent,_align,YGAlign);
SETENUMVALUE(alignItems,_align,YGAlign);
SETENUMVALUE(alignSelf,_align,YGAlign);
SETENUMVALUE(position,_positionType,YGPositionType);
SETENUMVALUE(flexWrap,_wrap,YGWrap);
SETENUMVALUE(overflow,_overflow,YGOverflow);
SETENUMVALUE(display,_display,YGDisplay);

    SETNUMVALUE(flexGrow);
    SETNUMVALUE(flexShrink);
    
    SETYGVALUE(left);
    SETYGVALUE(top);
    SETYGVALUE(right);
    SETYGVALUE(bottom);
    SETYGVALUE(start);
    SETYGVALUE(end);

    SETYGVALUE(marginLeft);
    SETYGVALUE(marginTop);
    SETYGVALUE(marginRight);
    SETYGVALUE(marginBottom);
    SETYGVALUE(marginStart);
    SETYGVALUE(marginEnd);
    SETYGVALUE(marginHorizontal);
    SETYGVALUE(marginVertical);
    SETYGVALUE(margin);
    
    SETYGVALUE(paddingLeft);
    SETYGVALUE(paddingTop);
    SETYGVALUE(paddingRight);
    SETYGVALUE(paddingBottom);
    SETYGVALUE(paddingStart);
    SETYGVALUE(paddingEnd);
    SETYGVALUE(paddingHorizontal);
    SETYGVALUE(paddingVertical);
    SETYGVALUE(padding);
    
    SETNUMVALUE(borderLeftWidth);
    SETNUMVALUE(borderTopWidth);
    SETNUMVALUE(borderRightWidth);
    SETNUMVALUE(borderBottomWidth);
    SETNUMVALUE(borderStartWidth);
    SETNUMVALUE(borderEndWidth);
    SETNUMVALUE(borderWidth);
    
    SETYGVALUE(width);
    SETYGVALUE(height);
    SETYGVALUE(minWidth);
    SETYGVALUE(minHeight);
    SETYGVALUE(maxWidth);
    SETYGVALUE(maxHeight);
    
    SETNUMVALUE(aspectRatio);
    
    NSLog(@"Flexbox: not supported layout attr - %@",key);
}

//增加对单一flex属性的支持，相当于同时设置flexGrow和flexShrink
void FlexApplyLayoutParam(YGLayout* layout,
                          NSString* key,
                          NSString* value)
{
    if( [key compare:@"flex" options:NSLiteralSearch]==NSOrderedSame)
    {
        ApplyLayoutParam(layout, @"flexShrink", value);
        ApplyLayoutParam(layout, @"flexGrow", value);
    }else{
        ApplyLayoutParam(layout, key, value);
    }
}
@interface FlexNode()

@property (nonatomic, strong) NSString* viewClassName;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* onPress;
@property (nonatomic, strong) NSArray<FlexAttr*>* layoutParams;
@property (nonatomic, strong) NSArray<FlexAttr*>* viewAttrs;
@property (nonatomic, strong) NSArray<FlexNode*>* children;

@end

@implementation FlexNode

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        _viewClassName = [coder decodeObjectForKey:VIEWCLSNAME];
        _name = [coder decodeObjectForKey:NAME];
        _onPress = [coder decodeObjectForKey:ONPRESS];
        _layoutParams = [coder decodeObjectForKey:LAYOUTPARAM];
        _viewAttrs = [coder decodeObjectForKey:VIEWATTRS];
        _children = [coder decodeObjectForKey:CHILDREN];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_viewClassName forKey:VIEWCLSNAME];
    [aCoder encodeObject:_name forKey:NAME];
    [aCoder encodeObject:_onPress forKey:ONPRESS];
    [aCoder encodeObject:_layoutParams forKey:LAYOUTPARAM];
    [aCoder encodeObject:_viewAttrs forKey:VIEWATTRS];
    [aCoder encodeObject:_children forKey:CHILDREN];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"FlexNode: %@, %@, %@, %@, %@", self.viewClassName, self.layoutParams, self.viewAttrs, self.children, self.onPress];
}

-(UIView*)buildViewTree:(NSObject*)owner
               RootView:(FlexRootView*)rootView
{
    if( self.viewClassName==nil){
        return nil;
    }
    Class cls = NSClassFromString(self.viewClassName) ;
    if(cls == nil){
        NSLog(@"Flexbox: class %@ not found.", self.viewClassName);
        return nil;
    }
    
    UIView* view = [[cls alloc]init];
    if(![view isKindOfClass:[UIView class]]){
        NSLog(@"Flexbox: %@ is not child class of UIView.", self.viewClassName);
        return nil;
    }
    
    if(self.name != nil){
        @try{
            view.viewAttrs.name = self.name ;
            [owner setValue:view forKey:self.name];
        }@catch(NSException* exception){
            NSLog(@"Flexbox: name %@ not found in owner %@",self.name,[owner class]);
        }@finally
        {
        }
    }
    
    if(self.onPress != nil){
        SEL sel = NSSelectorFromString(self.onPress);
        if(sel!=nil){
            if([owner respondsToSelector:sel]){
                UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc]initWithTarget:owner action:sel];
                tap.cancelsTouchesInView = NO;
                tap.delaysTouchesBegan = NO;
                [view addGestureRecognizer:tap];
            }else{
                NSLog(@"Flexbox: owner %@ not respond %@", [owner class] , self.onPress);
            }
        }else{
            NSLog(@"Flexbox: wrong onPress name %@", self.onPress);
        }
    }
    
    [view configureLayoutWithBlock:^(YGLayout* layout){
        
        layout.isEnabled = YES;
        
        NSArray<FlexAttr*>* layoutParam = self.layoutParams ;

        for (FlexAttr* attr in layoutParam) {
            if([attr.name compare:@"@" options:NSLiteralSearch]==NSOrderedSame){
                
                NSArray* ary = [[FlexStyleMgr instance]getStyleByRefPath:attr.value];
                for(FlexAttr* styleAttr in ary)
                {
                    FlexApplyLayoutParam(layout, styleAttr.name, styleAttr.value);
                }
                
            }else{
                FlexApplyLayoutParam(layout, attr.name, attr.value);
            }
        }
    }];
    
    if(self.viewAttrs.count > 0){
        NSArray<FlexAttr*>* attrParam = self.viewAttrs ;
        for (FlexAttr* attr in attrParam) {
            if([attr.name compare:@"@" options:NSLiteralSearch]==NSOrderedSame){
                
                NSArray* ary = [[FlexStyleMgr instance]getStyleByRefPath:attr.value];
                for(FlexAttr* styleAttr in ary)
                {
                    FlexSetViewAttr(view, styleAttr.name, styleAttr.value);
                }
                
            }else{
                FlexSetViewAttr(view, attr.name, attr.value);
            }
        }
    }
    
    if(self.children.count > 0){
        NSArray* children = self.children ;
        for(FlexNode* node in children){
            UIView* child = [node buildViewTree:owner RootView:rootView] ;
            if(child!=nil && ![child isKindOfClass:[FlexModalView class]])
            {
                [view addSubview:child];
            }
            
        }
    }
    
    if(![view isKindOfClass:[FlexModalView class]]){
        [rootView registSubView:view];
    }else{
        [(FlexModalView*)view setOwnerRootView:rootView];
    }
    
    [view postCreate];
    
    if(view.isHidden){
        view.yoga.isIncludedInLayout = NO ;
    }
    
    return view;
}

#pragma mark - build / parse
//用逗号分隔
+(NSArray*)seperateByComma:(NSString*)str
{
    NSMutableArray* result = [NSMutableArray array];
    
    int s = 0;
    int e;
    
    while (s<str.length) {
        
        for(e=s;e<str.length;e++){
            unichar c = [str characterAtIndex:e];
            if(c==',')
                break;
            if(c=='\\')
               e++;
        }
        if(e>=str.length){
            [result addObject:[str substringFromIndex:s]];
            break;
        }
        if(e>s){
            NSRange range = NSMakeRange(s,e-s);
            [result addObject:[str substringWithRange:range]];
        }
        s=e+1;
    }
    return result;
}
//
+(unichar)transChar:(unichar)c
{
    static unichar transTable[]={
        '\\','\\',
        't','\t',
        'r','\r',
        'n','\n',
    };
    int count = sizeof(transTable)/sizeof(unichar);
    
    for (int i=0;i<count;i+=2) {
        if(transTable[i] == c)
            return transTable[i+1];
    }
    return c;
}
//处理转义字符
+(NSString*)transString:(NSString*)str
{
    if([str rangeOfString:@"\\"].length==0)
        return str;
    
    NSMutableString* s = [str mutableCopy];
    
    for(int i=0;i<s.length;i++){
        unichar c = [s characterAtIndex:i];
        if(c!='\\'||i+1==s.length)
            continue;
        unichar next = [s characterAtIndex:i+1];
        next = [FlexNode transChar:next];
        NSString* sc=[NSString stringWithFormat:@"%C",next];
        [s replaceCharactersInRange:NSMakeRange(i, 2) withString:sc];
    }
    return [s copy];
}
+(NSArray*)parseStringParams:(NSString*)param
{
    if( param.length==0 )
        return nil;
    
    NSMutableArray* result = [NSMutableArray array];
    
    NSArray* parts = [FlexNode seperateByComma:param];
    NSCharacterSet* whiteSet = [NSCharacterSet whitespaceCharacterSet] ;
    
    for (NSString* part in parts)
    {
        NSRange range = [part rangeOfString:@":"];
        if(range.length == 0)
            continue;
        
        NSString* s1 = [part substringToIndex:range.location];
        NSString* s2 = [part substringFromIndex:range.location+1];
        
        FlexAttr* attr = [[FlexAttr alloc]init];
        attr.name = [s1 stringByTrimmingCharactersInSet:whiteSet];
        attr.value = [s2 stringByTrimmingCharactersInSet:whiteSet];
        attr.value = [FlexNode transString:attr.value];
        
        if(attr.isValid){
            [result addObject:attr];
        }
    }
    
    return [result copy];
}
+(FlexNode*)buildNodeWithXml:(GDataXMLElement*)element
{
    FlexNode* node = [[FlexNode alloc]init];
    node.viewClassName = [element name];
    
    // layout param
    GDataXMLNode* name = [element attributeForName:@"name"];
    if(name){
        node.name = [name stringValue];
    }
    
    // onPress
    GDataXMLNode* onpress = [element attributeForName:@"onPress"];
    if(onpress){
        node.onPress = [onpress stringValue];
    }
    
    // layout param
    GDataXMLNode* layout = [element attributeForName:@"layout"];
    if(layout){
        NSString* param = [layout stringValue];
        node.layoutParams = [FlexNode parseStringParams:param];
    }
    
    GDataXMLNode* attr = [element attributeForName:@"attr"];
    if(attr){
        NSString* param = [attr stringValue];
        node.viewAttrs = [FlexNode parseStringParams:param];
    }
    
    // children
    NSArray* children = [element children];
    if( children.count > 0 ){
        NSMutableArray* childNodes = [NSMutableArray array] ;
        
        for(GDataXMLElement* child in children){
            if(![child isKindOfClass:[GDataXMLElement class]]){
                continue;
            }
            [childNodes addObject:[FlexNode buildNodeWithXml:child]];
        }
        node.children = [childNodes copy] ;
    }
    
    return node;
}
+(FlexNode*)loadNodeData:(NSData*)xmlData
{
    if(xmlData == nil){
        return nil;
    }
    
    NSError* error = nil;
    GDataXMLDocument* xmlDoc = [[GDataXMLDocument alloc]initWithData:xmlData options:0 error:&error];
    
    if(error){
        NSLog(@"Flexbox: xml parse failed: %@",error);
        return nil;
    }
    
    GDataXMLElement* root=[xmlDoc rootElement];
    return [FlexNode buildNodeWithXml:root];
}
+(FlexNode*)loadNodeFromRes:(NSString*)flexName
{
    FlexNode* node;
    BOOL isAbsoluteRes = [flexName hasPrefix:@"/"];
    
    if(gbUserCache && !isAbsoluteRes){
        node = [FlexNode loadFromCache:flexName];
        if(node != nil)
            return node;
    }
    
    NSData* xmlData = isAbsoluteRes ? loadFromFile(flexName) : gLoadFunc(flexName) ;
    if(xmlData == nil){
        NSLog(@"Flexbox: flex res %@ load failed.",flexName);
        return nil;
    }
    node = [FlexNode loadNodeData:xmlData];
    

    if(gbUserCache && !isAbsoluteRes){
        dispatch_async(
                       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{
                           [FlexNode storeToCache:flexName Node:node];
                       });
    }
    return node;
}
+(NSString*)getCacheDir
{
    static NSString* documentPath;
    if(documentPath == nil){
        NSArray *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        documentPath = documents[0];
        documentPath = [documentPath stringByAppendingPathComponent:@"flex"];
        
        // create run flag
        
        NSDictionary* info = [[NSBundle mainBundle] infoDictionary];
        NSString *buildNumber = info[@"CFBundleVersion"];
        if(buildNumber == nil)
            buildNumber = @"0";
        buildNumber = [@"flex_run_" stringByAppendingString:buildNumber];

        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        BOOL alreadRun = [userDefaults boolForKey:buildNumber];
       
         NSFileManager* manager=[NSFileManager defaultManager];
        if( !alreadRun ){
            
            // clear the cache by last version
            [manager removeItemAtPath:documentPath error:NULL
             ];
            [manager createDirectoryAtPath:documentPath withIntermediateDirectories:YES attributes:nil error:nil];
            [userDefaults setBool:YES forKey:buildNumber];
        }else{
            if(![manager fileExistsAtPath:documentPath])
                [manager createDirectoryAtPath:documentPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    return documentPath;
}
+(void)clearFlexCache
{
    NSString* sCacheDir = [FlexNode getCacheDir];
    
    NSFileManager* manager=[NSFileManager defaultManager];
    [manager removeItemAtPath:sCacheDir error:NULL
         ];
    [manager createDirectoryAtPath:sCacheDir withIntermediateDirectories:YES attributes:nil error:nil];
}
+(NSString*)getResCachePath:(NSString*)flexName
{
    NSString* sFilePath = [FlexNode getCacheDir];
    sFilePath = [sFilePath stringByAppendingPathComponent:flexName];
    sFilePath = [sFilePath stringByAppendingString:@".flex"];
    return sFilePath;
}
+(FlexNode*)loadFromCache:(NSString*)flexName
{
    NSString* sFilePath = [FlexNode getResCachePath:flexName];
    
    FlexNode* node = [NSKeyedUnarchiver unarchiveObjectWithFile:sFilePath];

    return node;
}
+(void)storeToCache:(NSString*)flexName
               Node:(FlexNode*)node
{
    NSString* sFilePath = [FlexNode getResCachePath:flexName];
    [NSKeyedArchiver archiveRootObject:node toFile:sFilePath];
}
@end

NSData* loadFromFile(NSString* resName)
{
    NSString* path;
    
    if([resName hasPrefix:@"/"]){
        // it's absolute path
        path = resName ;
    }else{
        path = [[NSBundle mainBundle]pathForResource:resName ofType:@"xml"];
    }
    
    if(path==nil){
        NSLog(@"Flexbox: resource %@ not found.",resName);
        return nil;
    }
    return [NSData dataWithContentsOfFile:path];
}
NSData* loadFromNetwork(NSString* resName)
{
    NSError* error = nil;
    NSData* flexData = FlexFetchLayoutFile(resName, &error);
    if(error != nil){
        NSLog(@"Flexbox: loadFromNetwork error: %@",error);
    }
    return flexData;
}


void FlexRestorePreviewSetting(void)
{
#ifdef DEBUG
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    
    NSString* baseurl = [defaults objectForKey:FLEXBASEURL];
    BOOL onlineLoad = [defaults boolForKey:FLEXONLINELOAD];
    
    FlexSetPreviewBaseUrl(baseurl);
    FlexSetLoadFunc(onlineLoad?flexFromNet:flexFromFile);
#endif
}

void FlexSetLoadFunc(FlexLoadMethod loadFrom)
{
#ifdef DEBUG
    if(loadFrom == flexFromFile){
        gLoadFunc = loadFromFile ;
    }else if(loadFrom == flexFromNet){
        gLoadFunc = loadFromNetwork ;
    }else{
        NSLog(@"Flexbox: please call FlexSetCustomLoadFunc");
    }
#else
    gLoadFunc = loadFromFile ;
#endif
}
void FlexSetCustomLoadFunc(FlexLoadFunc func)
{
    gLoadFunc = func;
}
FlexLoadMethod FlexGetLoadMethod(void)
{
    if(gLoadFunc == loadFromFile)
        return flexFromFile;
    if(gLoadFunc == loadFromNetwork)
        return flexFromNet;
    return flexCustomLoad;
}
void FlexEnableCache(BOOL bEnable)
{
    gbUserCache = bEnable;
}
BOOL FlexIsCacheEnabled(void)
{
    return gbUserCache;
}