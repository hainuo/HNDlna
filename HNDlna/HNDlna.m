//
//  HNDlna.m
//  HNDlna
//
//  Created by hainuo on 2021/3/11.
//

#import "HNDlna.h"

BOOL _isPlaying;
BOOL isFirstSearch;
@interface HNDlna ()<DLNADelegate>

@property(nonatomic,strong) MRDLNA *dlnaManager;

@property(nonatomic,strong) NSArray *deviceArr;
@end

@implementation HNDlna

#pragma mark - APICLOOUD DEFAULT METHOD Override
+ (void)onAppLaunch:(NSDictionary *)launchOptions {
	// 方法在应用启动时被调用
	NSLog(@"HNDlna 模块应用启动回调被调用了");
}

- (id)initWithUZWebView:(UZWebView *)webView {
	if (self = [super initWithUZWebView:webView]) {
		// 初始化方法
		NSLog(@"HNDlna 模块 initWithUZWebView 方法被调用了");
	}
	return self;
}

- (void)dispose {
	// 方法在模块销毁之前被调用
	NSLog(@"HNDlna 模块 dispose 方法被调用了 模块即将被销毁");
    [[NSNotificationCenter defaultCenter] removeObserver:@"searchDevices"];
}

#pragma mark - DLNA delegate

/**
   DLNA局域网搜索设备结果
   @param devicesArray <CLUPnPDevice *> 搜索到的设备
 */
- (void)searchDLNAResult:(NSArray *)devicesArray {
	NSLog(@"发现设备 %@",devicesArray);

	_deviceArr = devicesArray;
    NSLog(@"发送searcheDevices通知");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"searchDevices" object:devicesArray];
};


/**
   投屏成功开始播放
 */
- (void)dlnaStartPlay {
	NSLog(@"投屏成功，开始播放");
};

#pragma mark - 检查代理方法

JS_METHOD(startSearch:(UZModuleMethodContext *)context){
	if(!_dlnaManager) {
		_dlnaManager = [MRDLNA sharedMRDLNAManager];
        _dlnaManager.delegate = self;
	}
	NSDictionary *param = context.param;
	NSString *searchTime = [param stringValueForKey:@"searchTime" defaultValue:nil];
    NSLog(@"获取到时间 %@",searchTime);
    if(!searchTime){
        searchTime = @"10";
    }
	[_dlnaManager setSearchTime:(int)searchTime];
	[_dlnaManager startSearch];
//	[NSThread sleepForTimeInterval:(int)searchTime];//当前进程暂停2秒钟
//    NSArray * ret = @[];
//    [ret setValue:[_deviceArr copy] forKeyPath:@"devices"];
//	[context callbackWithRet:ret err:nil delete:YES];
    __weak typeof(self) _self = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:@"searchDevices" object:self.deviceArr queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        
        NSLog(@"接收到searcheDevices通知");
            __strong typeof(_self) self = _self;
        if(!self) return ;
        
        NSLog(@"self deviceArr对象 %@",self.deviceArr);
        NSLog(@"note的object对象 %@",note.object);
       

        NSMutableDictionary * ret =[[NSMutableDictionary alloc] init];
        
//        NSMutableArray *array = [NSMutableArray array];
//        CLUPnPDevice *device;
//        for (device in note.object) {
//            [array addObject:@{@"name":device.friendlyName,@"uuid":device.uuid}];
//        }
        
        NSLog(@"array对象 %@",note.object);
        [ret setObject:note.object forKey:@"data"];
        NSLog(@"字典 %@",ret);
        [context callbackWithRet:ret err:nil delete:NO];
    }];

}

JS_METHOD(startDlna:(UZModuleMethodContext *)context){
	if(_dlnaManager) {
		NSDictionary *param = context.param;
		NSString *url = [param stringValueForKey:@"url" defaultValue:nil];
		NSString *xh = [param stringValueForKey:@"xh" defaultValue:nil];
        
        NSLog(@"deviceArr %@",_deviceArr);
		if(xh && url) {
			CLUPnPDevice *model = [_deviceArr objectAtIndex:(int)xh];
            if(model){
                NSLog(@"model  %@",model);
                //先设置url和设备信息
                _dlnaManager.device = model;
                _dlnaManager.playUrl = url;
                [_dlnaManager startDLNA];
                _isPlaying = YES;
                [context callbackWithRet:@{@"ret" : @{@"msg":@"投屏成功",@"code":@1}} err:nil delete:YES];
            }else{
                [context callbackWithRet:@{@"ret" : @{@"msg":@"投屏失败",@"code":@0}} err:nil delete:YES];
            }
		}else{
			[context callbackWithRet:@{@"ret":@{@"code":@0,@"msg":@"错误的请求数据"}} err:nil delete:YES];
		}
	}else{
		[context callbackWithRet:@{@"ret":@{@"code":@0,@"msg":@"错误的请求"}} err:nil delete:YES];
	}
}
JS_METHOD(endDlna:(UZModuleMethodContext *)context){
	if(_dlnaManager) {
		[_dlnaManager endDLNA];
		_isPlaying = NO;
        [context callbackWithRet:@{@"ret" : @{@"msg":@"启动成功",@"code":@1}} err:nil delete:YES];
	}else{
		[context callbackWithRet:@{@"ret":@{@"code":@0,@"msg":@"错误的请求"}} err:nil delete:YES];
	}
}

//播放下一个
JS_METHOD(playTheUrl:(UZModuleMethodContext *)context){
	if(_dlnaManager) {
		NSDictionary *param = context.param;
		NSString *url = [param stringValueForKey:@"url" defaultValue:nil];
		if(url) {
			[_dlnaManager playTheURL:url];
			_isPlaying = YES;
            [context callbackWithRet:@{@"ret" : @{@"msg":@"切换到下一集成功",@"code":@1}} err:nil delete:YES];
		}else{
			[context callbackWithRet:@{@"ret":@{@"code":@0,@"msg":@"错误的url"}} err:nil delete:YES];
		}
	}else{
		[context callbackWithRet:@{@"ret":@{@"code":@0,@"msg":@"错误的请求"}} err:nil delete:YES];
	}
}

@end

