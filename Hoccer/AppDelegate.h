//
//  AppDelegate.h
//  Hoccer
//
//  Created by Philip Brechler on 29.02.12.
//  Copyright (c) 2012 Hoccer GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreLocation/CoreLocation.h>
#import <Mapkit/Mapkit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBook/ABPeoplePickerView.h>

#import <Quartz/Quartz.h>

#import "Hoccer.h"
#import "HoccerContentFactory.h"
#import "HoccerContentFactoryDelegate.h"


@interface AppDelegate : NSObject <NSApplicationDelegate, HCLinccerDelegate, CLLocationManagerDelegate, MKMapViewDelegate, MKGeocoderDelegate, MKReverseGeocoderDelegate, NSTextFieldDelegate, QLPreviewPanelDataSource, QLPreviewPanelDelegate, HoccerContentFactoryDelegate> {
    HCLinccer *linccer;
    MKGeocoder *gCoder;
    MKReverseGeocoder *rGCoder;
    CLLocationManager *clManager;
    
    IBOutlet MKMapView *mapView;
    IBOutlet NSTextField *addressSearchField;
    IBOutlet NSMenu *mainMenu;
    IBOutlet NSMenu *groupMenu;
    IBOutlet NSPanel *settingsPanel;
    IBOutlet NSMenuItem *receivingMenuItem;
    
    IBOutlet NSPanel *peoplePickerPanel;
    IBOutlet ABPeoplePickerView *ppView;
    
    IBOutlet NSPanel *textPanel;
    IBOutlet NSTextView *textPanelTextView;
    
    IBOutlet NSPanel *swipePanel;
    IBOutlet NSImageView *swipePanelImage;
    
    NSStatusItem *groupStatus;
    NSMutableArray *groupArray;
    NSMutableArray *selectedClients;
    NSMutableArray *receivedContent;

    NSDictionary *sendingDictionary;
    
    NSTimer *receiveTimer;
    NSTimer *senderTimer;
    
    int failcounter;
    BOOL locationOverwrite;
    
}

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, retain)  NSDictionary *sendingDictionary;
- (IBAction)startReceiving:(id)sender;

- (IBAction)sendFile:(id)sender;
- (IBAction)sendText:(id)sender;
- (IBAction)sendvCard:(id)sender;
- (IBAction)searchAddress:(id)sender;
- (IBAction)quitApp:(id)sender;
- (IBAction)selectClient:(id)sender;
- (IBAction)showSettings:(id)sender;
- (IBAction)setLocation:(id)sender;
- (IBAction)selectvCard:(id)sender;
- (IBAction)sendTextInPanel:(id)sender;
- (void)receiveFile;
- (void)sendDict;
@end
