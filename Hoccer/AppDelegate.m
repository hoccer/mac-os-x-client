//
//  AppDelegate.m
//  Hoccer
//
//  Created by Philip Brechler on 29.02.12.
//  Copyright (c) 2012 Hoccer GmbH. All rights reserved.
//

#import "AppDelegate.h"
#import "NSString+URLHelper.h"
#import "NSFileManager+FileHelper.h"
#import "HoccerPreviewObject.h"


@implementation AppDelegate

@synthesize window = _window;
@synthesize sendingDictionary;

- (void)dealloc
{   
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [NSApp setServicesProvider:self];
    void NSUpdateDynamicServices(void);
    
    groupStatus = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
    [groupStatus setTitle:@"--"];
    [groupStatus setHighlightMode:YES];
    NSImage *menuImage = [NSImage imageNamed:@"hoccer-icon-22"];
    [groupStatus setImage:menuImage];
    [groupStatus setMenu:mainMenu];
    [menuImage release];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"autoKey"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"encryption"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"sendPassword"];
    linccer = [[HCLinccer alloc] initWithApiKey:API_KEY secret:SECRET sandboxed:USES_SANDBOX];
    linccer.delegate = self;
    
    NSMutableDictionary *userInfo = [[linccer.userInfo mutableCopy] autorelease];
    if (userInfo == nil) {
        userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    
    [userInfo setObject:[[NSHost currentHost] localizedName] forKey:@"client_name"];
    
    linccer.userInfo = userInfo;
    
    
    clManager = [[CLLocationManager alloc]init];
    clManager.delegate = self;
    [clManager startUpdatingLocation];
    
    mapView.delegate = self;
    mapView.showsUserLocation = YES;
    locationOverwrite = NO;
    
    [addressSearchField setTarget:self];
    [addressSearchField setAction:@selector(searchAddress:)];
    
   
    
    groupArray = [[NSMutableArray alloc]initWithCapacity:10];
    selectedClients = [[NSMutableArray alloc]initWithCapacity:10];
    receivedContent = [[NSMutableArray alloc] initWithCapacity:10];
    
    [[HoccerContentFactory sharedContentFactory] setDelegate:self];
    
    failcounter = 0;
}

- (void)linccerDidRegister:(HCLinccer *)linccer {
    NSLog(@"Registerd");
    
}

- (void)linccer:(HCLinccer *)linccer didFailWithError:(NSError *)error {
    NSLog(@"Error: %@",error);
    if (error.domain == HoccerError && error.code == HoccerNoReceiverError) {
        if (failcounter < 11) {
            [self sendDict];
            failcounter++;
        }
        else {
            [swipePanel orderOut:self];
        }
    }
}

- (void)linccer:(HCLinccer *)linncer didReceiveData:(NSArray *)data {
    [swipePanel orderOut:self];
    [receiveTimer invalidate];
    receiveTimer = nil;
    [receivingMenuItem setTitle:@"Start Receiving"];
    for (NSDictionary *receivedObject in data){
        NSArray *receivedData = [receivedObject objectForKey:@"data"];
        NSDictionary *receivedFile = [receivedData objectAtIndex:0];
        
        if ([[receivedFile objectForKey:@"type"] isEqualToString:@"text/x-vcard"]){
            ABAddressBook *tempBook = [ABAddressBook addressBook];
            ABPerson* person = [[ABPerson alloc] initWithVCardRepresentation:[[receivedFile objectForKey:@"content"] dataUsingEncoding:NSUTF8StringEncoding]];
            [tempBook addRecord:person];
            [tempBook save];
        }
        else if ([receivedFile objectForKey:@"uri"]){
            [[HoccerContentFactory sharedContentFactory] receiveFile:[receivedFile objectForKey:@"uri"]]; 
        }
        else if ([receivedFile objectForKey:@"content"]) {
            NSString *exportFile = [[NSFileManager defaultManager]uniqueFilenameForFilename:@"Received Text.txt" inDirectory:[@"~/Downloads/" stringByExpandingTildeInPath]]; 
            if ([[NSFileManager defaultManager] createFileAtPath:[[@"~/Downloads/" stringByExpandingTildeInPath] stringByAppendingPathComponent:exportFile] contents:[[receivedFile objectForKey:@"content"] dataUsingEncoding:NSUTF8StringEncoding]  attributes:nil]){
                HoccerPreviewObject *receivedObject = [[HoccerPreviewObject alloc]init];
                [receivedObject setFilePath:[[@"~/Downloads/" stringByExpandingTildeInPath] stringByAppendingPathComponent:exportFile] andTimeTag:[NSDate date]];
                [receivedContent addObject:receivedObject];
                [receivedObject release];
                [[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:nil];
            }
        }
    }
}



- (void)linccer:(HCLinccer *)linccer didUpdateGroup:(NSArray *)group {
    [groupArray removeAllObjects];
    for (NSDictionary *dict in group) {
        if (![[dict objectForKey:@"id"] isEqual:[self->linccer uuid]]) {
            [groupArray addObject:dict];            
        }
    }
    [groupStatus setTitle:[NSString stringWithFormat:@"%d",[groupArray count]]];
    
    [groupMenu removeAllItems];
    
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"name"  ascending:YES];
    [groupArray sortUsingDescriptors:[NSArray arrayWithObjects:descriptor,nil]];
    
    for (NSDictionary *dict in groupArray){
        NSString *clientName = [dict objectForKey:@"name"];
        NSMenuItem *groupMember = [[NSMenuItem alloc] initWithTitle:clientName action:@selector(selectClient:) keyEquivalent:@""];
        [groupMember setTag:[groupArray indexOfObject:dict]];
        
        for (NSString *string in selectedClients){
            if ([string isEqualToString:[dict objectForKey:@"id"]]){
                [groupMember setState:1];
            }
        }
        [groupMenu addItem:groupMember];
        [groupMember release];
    }
    
    
}

- (void)linccer:(HCLinccer *)linccer didSendData:(NSArray *)data {
    [senderTimer invalidate];
    senderTimer = nil;
    NSLog(@"Did send succesfully");
    [swipePanel orderOut:self];
    failcounter = 0;
}
- (void)receiveFile {
    [linccer receiveWithMode:HCTransferModeOneToOne];
    NSLog(@"Receiving");
}

- (IBAction)startReceiving:(id)sender {
    swipePanelImage.image = [NSImage imageNamed:@"swipe-out"];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:TRUE];
    [swipePanel makeKeyAndOrderFront:self];
    [self receiveFile];
    receiveTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(receiveFile) userInfo:nil repeats:YES];
    [receivingMenuItem setTitleWithMnemonic:@"Receiving…"];
}


- (IBAction)searchAddress:(id)sender
{
    //[mapView showAddress:[addressTextField stringValue]];
    gCoder = [[MKGeocoder alloc]initWithAddress:[addressSearchField stringValue]];
    gCoder.delegate = self;
    [gCoder start];
}


- (IBAction)sendFile:(id)sender{
    NSOpenPanel *fileToSendChooser	= [NSOpenPanel openPanel];
    fileToSendChooser.allowsMultipleSelection = NO;
    NSInteger fileToSendChooserButton	= [fileToSendChooser runModal];
    if(fileToSendChooserButton == NSOKButton){
        NSURL *choosenFileURL = [fileToSendChooser URL];
        NSLog(@"doOpen filename = %@",choosenFileURL);	
        
        [[HoccerContentFactory sharedContentFactory] sendingItemWithFile:choosenFileURL];
    } else if(fileToSendChooserButton == NSCancelButton) {
     	return;
    } else {
     	return;
    }     
    
    
}
- (IBAction)sendvCard:(id)sender{
    [[NSApplication sharedApplication] activateIgnoringOtherApps:TRUE];
    [peoplePickerPanel makeKeyAndOrderFront:self];
}

- (IBAction)selectvCard:(id)sender{
    [peoplePickerPanel orderOut:self];
    ABPerson *selectedContact = [[ppView selectedRecords] lastObject];
    [[HoccerContentFactory sharedContentFactory] sendingItemWithvCardString:[[NSString alloc] initWithData:[selectedContact vCardRepresentation] encoding:NSUTF8StringEncoding]];
}

- (IBAction)selectMyvCard:(id)sender{
    ABPerson *selectedContact = [[ABAddressBook sharedAddressBook] me];
    [[HoccerContentFactory sharedContentFactory] sendingItemWithvCardString:[[NSString alloc] initWithData:[selectedContact vCardRepresentation] encoding:NSUTF8StringEncoding]];
    
}
- (IBAction)sendText:(id)sender{
    [[NSApplication sharedApplication] activateIgnoringOtherApps:TRUE];
    [textPanel makeKeyAndOrderFront:self];
}

- (IBAction)sendTextInPanel:(id)sender {
    [[HoccerContentFactory sharedContentFactory] sendingItemWithString:[[textPanelTextView textStorage] string]];
    [textPanel orderOut:self];
    [[textPanelTextView textStorage] setAttributedString:[[NSAttributedString alloc]initWithString:@""]];
}
- (IBAction)quitApp:(id)sender{
    exit(0);
}

- (IBAction)selectClient:(id)sender {
    NSMenuItem *theSender = [sender retain];
    NSLog(@"Selected: %@",theSender.title);
    
    NSDictionary *selectedClient = [groupArray objectAtIndex:theSender.tag];
    
    
    NSMutableDictionary *userInfo = [[linccer.userInfo mutableCopy] autorelease];
    if (userInfo == nil) {
        userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    
    
    NSLog(@"State: %ld",theSender.state);
    
    switch (theSender.state) {
        case 0:
            theSender.state = 1;
            [selectedClients addObject:[selectedClient objectForKey:@"id"]];
            
            break;
        case 1:
            theSender.state = 0;
            long i = 0;
            for (NSString *string in selectedClients){
                if ([string isEqualToString:[selectedClient objectForKey:@"id"]]){
                    i = [selectedClients indexOfObject:string];
                }
            }
            [selectedClients removeObjectAtIndex:i];
            break;
        default:
            break;
    }
    [userInfo setObject:selectedClients forKey:@"selected_clients"];
    
    linccer.userInfo = userInfo;
    
}

- (IBAction)showSettings:(id)sender {
    
    [[NSApplication sharedApplication] activateIgnoringOtherApps:TRUE];
    [settingsPanel makeKeyAndOrderFront:self];
    if (clManager.location != nil && !locationOverwrite) {
        [mapView setCenterCoordinate:clManager.location.coordinate animated:NO];
    }
    else if (clManager.location == nil){
        [mapView setCenterCoordinate:CLLocationCoordinate2DMake(52.5165076, 13.408945) animated:NO];
    }
}

- (IBAction)setLocation:(id)sender {
    [clManager startUpdatingLocation];
    mapView.showsUserLocation = YES;
    locationOverwrite = NO;
    [mapView removeAnnotations:mapView.annotations];
}

# pragma mark MKGeocoderDelegate
- (void)geocoder:(MKGeocoder *)geocoder didFindCoordinate:(CLLocationCoordinate2D)coordinate {
    NSLog(@"Found it");
    [mapView removeAnnotations:mapView.annotations];
    [addressSearchField.cell setPlaceholderString: @" "];
    [mapView setCenterCoordinate:coordinate];
    MKPointAnnotation *pin = [[[MKPointAnnotation alloc] init] autorelease];
    pin.coordinate = coordinate;
    pin.title = @"Found location";
    [mapView addAnnotation:pin];
    [linccer overwriteLocationWithCoordinate:coordinate];
    locationOverwrite = YES;
    [gCoder release];
}

- (void)geocoder:(MKGeocoder *)geocoder didFailWithError:(NSError *)error {
    [addressSearchField setTitleWithMnemonic:@""];
    [addressSearchField.cell setPlaceholderString: @"Could not find that"];
    
}

- (MKAnnotationView *)mapView:(MKMapView *)aMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    
    MKPinAnnotationView *view = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"Pin"] autorelease];
    view.draggable = NO;
    mapView.showsUserLocation = NO;
    return view;
}

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFailWithError:(NSError *)error {
    [addressSearchField setTitleWithMnemonic:@""];
    
    [addressSearchField.cell setPlaceholderString: @"Could not find any address"];
}

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFindPlacemark:(MKPlacemark *)placemark {
    if (!locationOverwrite){
        [addressSearchField.cell setPlaceholderString:[NSString stringWithFormat:@"%@, %@, %@",placemark.thoroughfare, placemark.locality, placemark.country]];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    if (!locationOverwrite){
        [mapView setCenterCoordinate:newLocation.coordinate];
        rGCoder = [[MKReverseGeocoder alloc]initWithCoordinate:newLocation.coordinate];
        [rGCoder setDelegate:self];
        [rGCoder start];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if (!locationOverwrite){    
        [self showSettings:nil];
    }
}

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
    locationOverwrite = YES;
    [clManager stopUpdatingLocation];
    return YES;
}

# pragma mark QLLookDelegate

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel;
{
    return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel
{
    // This document is now responsible of the preview panel
    // It is allowed to set the delegate, data source and refresh panel.
    panel.delegate = self;
    panel.dataSource = self;
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel
{
    // This document loses its responsisibility on the preview panel
    // Until the next call to -beginPreviewPanelControl: it must not
    // change the panel's delegate, data source or refresh it.
    
}

// Quick Look panel data source

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel
{
    return 1;
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index
{
    return [receivedContent lastObject];
}

#pragma mark HoccerContentFactoryDelegate

- (void)sendDict {
    if (!linccer.isRegistered || linccer.isLinccing || !self.sendingDictionary){
        return;
    }
    else {
        [linccer send:self.sendingDictionary withMode:HCTransferModeOneToOne];
        NSLog(@"Sending");
    }
}

- (void)hoccerContentFactoryHasFinishedDataRepresentation:(NSDictionary *)repr {
    swipePanelImage.image = [NSImage imageNamed:@"swipe-in"];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:TRUE];
    [swipePanel makeKeyAndOrderFront:self];
    self.sendingDictionary = [NSDictionary dictionaryWithDictionary:repr];
    [self sendDict];
}

- (void)hoccerContentFactoryDidReceiveFile:(NSData *)file forURI:(NSString *)string response:(NSHTTPURLResponse *)response {
    if (response.statusCode == 200){
        NSString *exportFile = [[NSFileManager defaultManager]uniqueFilenameForFilename: response.suggestedFilename inDirectory:[@"~/Downloads/" stringByExpandingTildeInPath]]; 
        if ([[NSFileManager defaultManager] createFileAtPath:[[@"~/Downloads/" stringByExpandingTildeInPath] stringByAppendingPathComponent:exportFile] contents:file attributes:nil]){
            HoccerPreviewObject *receivedObject = [[HoccerPreviewObject alloc]init];
            [receivedObject setFilePath:[[@"~/Downloads/" stringByExpandingTildeInPath] stringByAppendingPathComponent:exportFile] andTimeTag:[NSDate date]];
            [receivedContent addObject:receivedObject];
            [receivedObject release];
            [[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:nil];
        }
    }
}

- (void)hoccSelectedItem:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error{
    NSLog(@"We are there");
}
@end
