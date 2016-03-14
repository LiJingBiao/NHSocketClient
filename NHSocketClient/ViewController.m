//
//  ViewController.m
//  NHSocketClient
//
//  Created by hu jiaju on 16/3/11.
//  Copyright © 2016年 hu jiaju. All rights reserved.
//

#define PBFormat(format, ...) [NSString stringWithFormat:format,##__VA_ARGS__]

#import "ViewController.h"

typedef enum {
    ProtocolTypeNone,
    ProtocolTypeTCP,
    ProtocolTypeUDP
}ProtocolType;

@interface ViewController ()<GCDAsyncUdpSocketDelegate,GCDAsyncSocketDelegate,NSTableViewDataSource,NSTableViewDelegate,NSTextFieldDelegate,NSTextViewDelegate>

@property (nonatomic, strong) NSString *ipServer,*port;
@property (nonatomic, strong) NSTextField *ipfd;
@property (nonatomic, strong) NSTextField *portfd;
@property (nonatomic, strong) NSTextField *sendfd;
@property (nonatomic, strong) NSButton *connectBtn;
@property (nonatomic, assign) ProtocolType type;
@property (nonatomic, assign) BOOL isConnected;
@property (nonatomic, assign) NSInteger personIndex;
@property (nonatomic, strong) NSPopUpButton *userPop,*protocolPop;
@property (nonatomic, assign) CGFloat infoWidth;

@property (nonatomic, strong) GCDAsyncUdpSocket *udpServer;
@property (nonatomic, strong) GCDAsyncSocket *tcpServer;
@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, strong) NSScrollView *container;
@property (nonatomic, strong) NSTableView *msgTable;
@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    self.view.window.backgroundColor = [NSColor whiteColor];
    CGFloat offset = 30;
    
    [self.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(@700);
        make.height.mas_equalTo(@500);
    }];
    
    NSPopUpButton *perBtn = [NSPopUpButton new];
    [perBtn setTarget:self];
    [perBtn setAction:@selector(loginPerson:)];
    [self.view addSubview:perBtn];
    [perBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(self.view).offset(offset);
        make.width.equalTo(@100);
    }];
    [perBtn addItemsWithTitles:@[@"user-1",@"user-2",@"user-3",@"user-4"]];
    self.personIndex = 1;
    self.userPop = perBtn;
    
    NSPopUpButton *popBtn = [NSPopUpButton new];
    [popBtn setAction:@selector(popEvent:)];
    [popBtn setTarget:self];
    [self.view addSubview:popBtn];
    [popBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(offset);
        make.width.equalTo(@100);
        make.top.equalTo(perBtn.mas_bottom).offset(offset*0.5);
    }];
    [popBtn addItemsWithTitles:@[@"选择协议",@"None",@"TCP",@"UDP"]];
    [popBtn selectItemAtIndex:2];self.type = ProtocolTypeTCP;
    self.protocolPop = popBtn;
    
    NSTextField *label = [NSTextField new];
    label.placeholderString = @"输入server IP";
    label.stringValue = @"127.0.0.1";
    //label.stringValue = @"192.168.11.236";
    [self.view addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(offset);
        make.top.equalTo(popBtn.mas_bottom).offset(offset*0.5);
        make.width.equalTo(@100);
    }];
    self.ipfd = label;
    
    NSTextField *port = [NSTextField new];
    port.placeholderString = @"输入server port";
    //port.stringValue = @"8080";
    port.stringValue = @"31500";
    [self.view addSubview:port];
    [port mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(offset);
        make.top.equalTo(label.mas_bottom).offset(offset*0.5);
        make.width.equalTo(@100);
    }];
    self.portfd = port;
    
    NSButton *connect = [NSButton new];
    [self.view addSubview:connect];
    [connect setTitle:@"Connect"];
    [connect setAction:@selector(connectEvent)];
    [connect setTarget:self];
    [connect mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(offset);
        make.top.equalTo(port.mas_bottom).offset(offset*0.5);
        make.width.equalTo(@100);
        //make.bottom.equalTo(self.view).offset(-offset);
    }];
    self.connectBtn = connect;
    
//    NSButton *send = [NSButton new];
//    [self.view addSubview:send];
//    [send setTitle:@"Send"];
//    [send setAction:@selector(sendEvent)];
//    [send setTarget:self];
//    [send mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.equalTo(self.view).offset(offset);
//        make.top.equalTo(connect.mas_bottom).offset(offset*0.5);
//        make.width.equalTo(@100);
//        //make.bottom.equalTo(self.view).offset(-offset);
//    }];
    
    NSRect bounds = NSMakeRect(0, 0, 100, 100);
    NSScrollView *container = [[NSScrollView alloc] initWithFrame:bounds];
    //container.backgroundColor = [NSColor redColor];
    NSTableView *table = [[NSTableView alloc] initWithFrame:bounds];
    table.backgroundColor = [NSColor whiteColor];
    NSTableColumn *coloumn = [[NSTableColumn alloc] initWithIdentifier:@"colum1"];
    [coloumn setWidth:300];
    [table addTableColumn:coloumn];
    [container setDocumentView:table];
    [container setHasVerticalScroller:true];
//    [table mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.edges.equalTo(container).insets(NSEdgeInsetsMake(5, 5, 5, 5));
//    }];
    table.headerView = nil;
    table.dataSource = self;
    table.delegate = self;
    [table reloadData];
    [self.view addSubview:container];
    [container mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view).insets(NSEdgeInsetsMake(offset, offset*5, offset*5, offset));
    }];
    self.msgTable = table;
    self.container = container;
    self.infoWidth = self.msgTable.bounds.size.width;
    
    NSTextField *textv = [NSTextField new];
    textv.backgroundColor = [NSColor lightGrayColor];
    [self.view addSubview:textv];
    [textv mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(offset*5);
        make.top.equalTo(container.mas_bottom).offset(offset);
        make.width.equalTo(container.mas_width);
        make.bottom.equalTo(self.view).offset(-offset);
    }];
    textv.delegate = self;
    self.sendfd = textv;
}

- (NSMutableArray *)dataSource {
    if (!_dataSource) {
        _dataSource = [NSMutableArray arrayWithCapacity:0];
    }
    return _dataSource;
}

- (void)loginPerson:(NSPopUpButton *)btn {
    NSInteger index = btn.indexOfSelectedItem;
    self.personIndex = index;
}

- (void)popEvent:(NSPopUpButton *)btn {
    NSInteger index = btn.indexOfSelectedItem;
    NSLog(@"index:%zd",btn.indexOfSelectedItem);
    
    if (index < 2) {
        //disconnect
        self.type = ProtocolTypeNone;
    }else if (index == 2){
        self.type = ProtocolTypeTCP;
    }else if (index == 3){
        self.type = ProtocolTypeUDP;
    }
}

- (void)connectEvent {
    
    if ([self isConnected]) {
        [self disconnect];
        return;
    }
    
    if (self.type == ProtocolTypeNone) {
        [MLHudAlert alertWithWindow:self.view.window type:MLHudAlertTypeError message:@"请选择协议！"];
        return;
    }
    
    NSString *ip = self.ipfd.stringValue;
    if (ip.length == 0) {
        [MLHudAlert alertWithWindow:self.view.window type:MLHudAlertTypeError message:@"请输入ip！"];
        NSLog(@"请输入ip");
        return;
    }
    
    NSString *fomart = @"((2[0-4]\\d|25[0-5]|[01]?\\d\\d?)\\.){3}(2[0-4]\\d|25[0-5]|[01]?\\d\\d?)";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",fomart];
    if (![predicate evaluateWithObject:ip]) {
        [MLHudAlert alertWithWindow:self.view.window type:MLHudAlertTypeError message:@"请输入正确的ip！"];
        return;
    }
    self.ipServer = [ip copy];
    
    NSString *port = self.portfd.stringValue;
    if (port.integerValue <= 0 || port.integerValue > 65535) {
        [MLHudAlert alertWithWindow:self.view.window type:MLHudAlertTypeError message:@"请输入正确的端口号！"];
        return;
    }
    self.port = [port copy];
    
    [self realStartConnect];
}

- (void)disconnect {
    if (![self isConnected]) {
        return;
    }
    
    if (self.type == ProtocolTypeUDP) {
        [self.udpServer close];
    }else if (self.type == ProtocolTypeTCP){
        [self.tcpServer disconnect];
    }
    
    [self disableUserInterfaceAfterConnected];
}

- (void)disableUserInterfaceAfterConnected {
    BOOL enable = ![self isConnected];
    
    self.userPop.enabled = enable;
    self.protocolPop.enabled = enable;
    self.ipfd.enabled = enable;
    self.portfd.enabled = enable;
    
    NSString *title = enable?@"Connect":@"Disconnect";
    [self.connectBtn setTitle:title];
}

- (void)realStartConnect {
    
    if (self.type == ProtocolTypeUDP) {
        if (!_udpServer) {
            _udpServer = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        }
        NSError *error = nil;
        if (![_udpServer bindToPort:0 error:&error]) {
            [MLHudAlert alertWithWindow:self.view.window type:MLHudAlertTypeError message:error.localizedDescription];
            [self disableUserInterfaceAfterConnected];
            return;
        }
        if (![_udpServer beginReceiving:&error]) {
            [MLHudAlert alertWithWindow:self.view.window type:MLHudAlertTypeError message:error.localizedDescription];
            [self disableUserInterfaceAfterConnected];
            return;
        }
        
        [MLHudAlert alertWithWindow:self.view.window type:MLHudAlertTypeSuccess message:@"绑定成功!"];
    }else if (self.type == ProtocolTypeTCP){
        if (!_tcpServer) {
            _tcpServer = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        }
        
        NSError *error = nil;
        if (![self.tcpServer connectToHost:self.ipServer onPort:[self.port intValue] error:&error]) {
            [MLHudAlert alertWithWindow:self.view.window type:MLHudAlertTypeError message:error.localizedDescription];
            [self disableUserInterfaceAfterConnected];
            return;
        }
        
        [MLHudAlert alertWithWindow:self.view.window type:MLHudAlertTypeSuccess message:@"建立通道成功!"];
    }
    
    [self disableUserInterfaceAfterConnected];
}

- (void)updateSendState {
   
}

- (void)sendEvent {
    
    if (![self isConnected]) {
        [MLHudAlert alertWithWindow:self.view.window type:MLHudAlertTypeError message:@"请选择协议并连接 socket server！"];
        return;
    }
    
    NSString *msg = [self msg];
    NSLog(@"将要发送的消息:%@---%zd",msg,_tag);
    NSData *data = [msg dataUsingEncoding:NSUTF8StringEncoding];
    if (self.type == ProtocolTypeUDP) {
        //int port = _udpServer.localPort;
        //NSLog(@"local port :%d",port);
        [self.udpServer sendData:data toHost:self.ipServer port:[self.port intValue] withTimeout:-1 tag:_tag];
    }else if (self.type == ProtocolTypeTCP){
        [self.tcpServer writeData:data withTimeout:-1 tag:_tag];
    }
    _tag++;
}

- (BOOL)isConnected {
    BOOL ret = false;
    if (self.type == ProtocolTypeUDP && self.udpServer && !self.udpServer.isClosed) {
        ret = true;
    }
    if (self.type == ProtocolTypeTCP && self.tcpServer && self.tcpServer.isConnected) {
        ret = true;
    }
    return ret;
}

- (NSString *)msg {
    NSInteger random = arc4random()%10000;
    return [NSString stringWithFormat:@"random msg :%zd",random];
}

- (void)readNewMsg {
    //[self.tcpServer readDataToLength:10 withTimeout:-1 tag:_tag];
    [self.tcpServer readDataWithTimeout:-1 tag:_tag];
}

#pragma mark -- UDP delegate --

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address {
    NSLog(@"--%s",__FUNCTION__);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError *)error {
    NSLog(@"--%s",__FUNCTION__);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    NSLog(@"didSendDataWithTag--%zd",tag);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error {
    NSLog(@"didNotSendDataWithTag:%zd--error:%@",tag,error.localizedDescription);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"didReceiveData--%@",msg);
    [self alreadyReceiveMsg:msg];
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error {
    NSLog(@"--%s--error:%@",__FUNCTION__,error.localizedDescription);
    [self disableUserInterfaceAfterConnected];
}

#pragma mark -- TCP Delegate --

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"didConnectToHost:%@",host);
    [self disableUserInterfaceAfterConnected];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    
    NSLog(@"didWriteDataWithTag:%zd",tag);
    
    [self readNewMsg];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"didReadData:%@",msg);
    [self alreadyReceiveMsg:msg];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"--%s--error:%@",__FUNCTION__,err.localizedDescription);
    [MLHudAlert alertWithWindow:self.view.window type:MLHudAlertTypeError message:err.localizedDescription];
    [self disableUserInterfaceAfterConnected];
}

#pragma mark -- NSTextField Delegate --

- (void)controlTextDidBeginEditing:(NSNotification *)obj {
    //NSLog(@"%s",__func__);
}

- (void)controlTextDidChange:(NSNotification *)obj {
    //NSLog(@"%s",__func__);
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    
    if (![self isConnected]) {
        [MLHudAlert alertWithWindow:self.view.window type:MLHudAlertTypeError message:@"请选择协议并连接 socket server！"];
        return;
    }
    
    //NSLog(@"%s--%@",__func__,obj.object);
    NSTextField *tmp = (NSTextField *)obj.object;
    if (tmp == self.sendfd) {
        NSString *info = self.sendfd.stringValue;
        if (info.length > 0) {
            NSLog(@"将要发送的消息:%@---%zd",info,_tag);
            NSData *data = [info dataUsingEncoding:NSUTF8StringEncoding];
            if (self.type == ProtocolTypeUDP) {
                //int port = _udpServer.localPort;
                //NSLog(@"local port :%d",port);
                [self.udpServer sendData:data toHost:self.ipServer port:[self.port intValue] withTimeout:-1 tag:_tag];
            }else if (self.type == ProtocolTypeTCP){
                [self.tcpServer writeData:data withTimeout:-1 tag:_tag];
                //[self readNewMsg];
            }
            [self alreadySendMsg:info];
            _tag++;
        }
    }
}

- (void)alreadySendMsg:(NSString *)info {
    NSDictionary *tmp = [NSDictionary dictionaryWithObjectsAndKeys:@"me",@"from",info,@"info", nil];
    self.sendfd.stringValue = @"";
    [self.dataSource addObject:tmp];
    [self.msgTable reloadData];
    [self.msgTable scrollToEndOfDocument:self.msgTable];
    
}

- (void)alreadyReceiveMsg:(NSString *)info {
    NSDictionary *tmp = [NSDictionary dictionaryWithObjectsAndKeys:@"other",@"from",info,@"info", nil];
    [self.dataSource addObject:tmp];
    [self.msgTable reloadData];
    [self.msgTable scrollToEndOfDocument:self.msgTable];
}

#pragma mark -- Table Datasource --

#define TEXT_OFFSET     20
#define TEXT_FONT_SIZE  15
#define TEXT_FONT    [NSFont fontWithName:@"HelveticaNeue-Light" size:TEXT_FONT_SIZE]

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.dataSource.count;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    
    NSDictionary *tmp = [self.dataSource objectAtIndex:row];
    NSString *fromer = [tmp objectForKey:@"from"];
    NSString *info = [tmp objectForKey:@"info"];
    BOOL fromMe = [fromer isEqualToString:@"me"];
    NSString *displayInfo = fromMe?PBFormat(@"%@:me",info):PBFormat(@"server:%@",info);
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:TEXT_FONT,NSFontAttributeName, nil];
    NSSize maxSize = [displayInfo sizeWithAttributes:attributes];;
    NSLog(@"cell height:%f",maxSize.height+TEXT_OFFSET);
    return maxSize.height+TEXT_OFFSET;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    static NSString *identifier = @"cell";
    
    NSDictionary *tmp = [self.dataSource objectAtIndex:row];
    NSString *fromer = [tmp objectForKey:@"from"];
    NSString *info = [tmp objectForKey:@"info"];
    BOOL fromMe = [fromer isEqualToString:@"me"];
    NSView *cell = [tableView makeViewWithIdentifier:identifier owner:self];
    NSString *displayInfo = fromMe?PBFormat(@"%@:me",info):PBFormat(@"server:%@",info);
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:TEXT_FONT,NSFontAttributeName, nil];
    NSSize maxSize = [displayInfo sizeWithAttributes:attributes];
    NSRect bounds ;
    bounds.origin = CGPointZero;
    bounds.size = NSMakeSize(maxSize.width, maxSize.height+TEXT_OFFSET);
    if (cell == nil) {
        cell = [[NSView alloc] initWithFrame:bounds];
        cell.identifier = identifier;
    }
    [cell.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSRect textBounds ;
    textBounds.origin = CGPointZero;
    //textBounds.origin = NSMakePoint(fromMe?(tableColumn.width-maxSize.width-TEXT_OFFSET):0, TEXT_OFFSET*0.5);
    textBounds.size = CGSizeMake(maxSize.width,maxSize.height);
    NSColor *textColor = fromMe?[NSColor lightGrayColor]:[NSColor blueColor];
    NSTextField *view = [[NSTextField alloc] initWithFrame:textBounds];
    view.lineBreakMode = NSLineBreakByCharWrapping;
    [view setBezeled:NO];
    [view setDrawsBackground:NO];
    [view setEditable:NO];
    [view setSelectable:NO];
    //view.backgroundColor = fromMe?[NSColor lightGrayColor]:[NSColor whiteColor];
    view.font = TEXT_FONT;
    [view setAlignment:fromMe?NSTextAlignmentRight:NSTextAlignmentLeft];
    view.stringValue = displayInfo;
    view.textColor = textColor;
    [cell addSubview:view];
    view.backgroundColor = [NSColor redColor];
    NSLog(@"table width :%f",tableColumn.width);
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(cell).offset(TEXT_OFFSET*0.5);
        if (fromMe) {
            make.right.equalTo(cell).offset(-TEXT_OFFSET*0.5);
        }
    }];
    
    return cell;
}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
    
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
