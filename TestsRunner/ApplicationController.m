//
//  ApplicationController.m
//  TestsRunner
//
//  Created by Patrick Geiller on 17/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ApplicationController.h"
#import "JSCocoa.h"

@implementation ApplicationController

JSCocoaController* jsc = nil;

//- (void)awakeFromNib
- (void)applicationDidFinishLaunching:(id)notif
{
//	NSLog(@"DEALLOC AUTORELEASEPOOL");
//	[JSCocoaController deallocAutoreleasePool];
//	[[NSAutoreleasePool alloc] init];




//	jsc = [JSCocoaController sharedController];
	jsc = [JSCocoa new];




//	[[JSCocoaController sharedController] evalJSFile:[[NSBundle mainBundle] pathForResource:@"class" ofType:@"js"]];
/*	
	JSValueRef v;
	v = [[JSCocoaController sharedController] callJSFunctionNamed:@"test1" withArguments:[NSNumber numberWithInt:3], [NSNumber numberWithInt:5], @"hello!!", nil];
	NSLog(@">>RET=%@", [[JSCocoaController sharedController] formatJSException:v]);
	v = [[JSCocoaController sharedController] callJSFunctionNamed:@"test2" withArguments:nil];
	NSLog(@">>RET=%@", [[JSCocoaController sharedController] formatJSException:v]);
*/	
//	[[JSCocoaController sharedController] callJSFunctionNamed:@"test1" withArguments:self];
/*
	JSValueRef value = [[JSCocoaController sharedController] callJSFunctionNamed:@"test1" withArguments:@"myself", nil];
	id object;
	id object2 = [[JSCocoaController sharedController] unboxJSValueRef:value];
	[JSCocoaFFIArgument unboxJSValueRef:value toObject:&object inContext:[[JSCocoaController sharedController] ctx]];
	NSLog(@"result=*%@*%@*", object, object2);
*/	
	
/*
	NSRect rect = { 10, 20, 30, 40 };
	NSRect rect1, rect2;
	NSDivideRect(rect, &rect1, &rect2, 5, 0);
	float* r;
	r = &rect;	NSLog(@"r=%f, %f, %f, %f", r[0], r[1], r[2], r[3]);
	r = &rect1;	NSLog(@"r1=%f, %f, %f, %f", r[0], r[1], r[2], r[3]);
	r = &rect2;	NSLog(@"r2=%f, %f, %f, %f", r[0], r[1], r[2], r[3]);
*/	

/*
	CGColorRef color = CGColorCreateGenericRGB(1.0, 0.8, 0.6, 0.2);
	const CGFloat* colors = CGColorGetComponents(color);
	NSLog(@"%f %f %f %f %f", colors[0], colors[1], colors[2], colors[3], colors[4]);
	
	CGColorRelease(color);
*/
	[[NSApplication sharedApplication] setDelegate:self];
	[self performSelector:@selector(runJSTests:) withObject:nil afterDelay:0];
//	[self performSelector:@selector(runJSTests:) withObject:nil afterDelay:0];
}

- (void)applicationWillTerminate:(id)notif
{
	[jsc unlinkAllReferences];
	[jsc garbageCollect];
	NSLog(@"willTerminate %@ %d", jsc, [jsc retainCount]);
	[jsc release];
}


//
// Run unit tests + delegate tests
//
int runCount = 0;

- (IBAction)runJSTests:(id)sender
{
	runCount++;

	id path = [[NSBundle mainBundle] bundlePath];
	path = [NSString stringWithFormat:@"%@/Contents/Resources/Tests", path];
//	NSLog(@"Run %d from %@", runCount, path);
	BOOL b = [jsc runTests:path];
	[self garbageCollect:nil];

	// Test delegate
	id error = [self testDelegate];
	if (error)
	{
		b = NO;
		path = error;
	}
	jsc.delegate = nil;
	
	if (!b)	{	NSLog(@"!!!!!!!!!!!FAIL %d from %@", runCount, path); return; }
	else	NSLog(@"All tests ran OK !");
}

//
// GC
//
- (IBAction)garbageCollect:(id)sender
{
	[jsc garbageCollect];
}


- (IBAction)runSimpleTestFile:(id)sender
{
	id js = @"2+2";
	js = @"NSWorkspace.sharedWorkspace.activeApplication";

	js = @"var a = NSMakePoint(2, 3)";


	[JSCocoaController garbageCollect];
//	JSValueRefAndContextRef v = [[JSCocoaController sharedController] evalJSString:js];
//	JSValueRefAndContextRef v = [jsc evalJSString:js];
	JSValueRef ret = [jsc evalJSString:js];
	[JSCocoaController garbageCollect];
	
//	JSStringRef resultStringJS = JSValueToStringCopy(v.ctx, v.value, NULL);
	JSStringRef resultStringJS = JSValueToStringCopy([jsc ctx], ret, NULL);
	NSString* r = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, resultStringJS);
	JSStringRelease(resultStringJS);
	
	NSLog(@"res=%@", r);
	[r release];
}

- (IBAction)unlinkAllReferences:(id)sender
{
//	[JSCocoa logInstanceStats];
//	[[JSCocoaController sharedController] unlinkAllReferences];
	[jsc unlinkAllReferences];
//	[self garbageCollect:nil];
//	[JSCocoa logInstanceStats];
}



//
// Delegate testing
//
BOOL	hadError;

BOOL	canGet;
id		object;
id		propertyName;

JSValueRef	customValue;

- (id)testDelegate
{
	jsc.delegate = self;

	JSValueRef ret;

	//
	// Test disallowed getting
	//
	canGet		= NO;
	hadError	= NO;
	ret = [jsc evalJSString:@"NSWorkspace.sharedWorkspace"];
	if (!hadError)		return	@"delegate canGetProperty failed (1)";
	
	//
	// Test allowed getting
	//
	canGet		= YES;
	customValue	= NULL;
	ret = [jsc evalJSString:@"NSWorkspace.sharedWorkspace"];
	if (object != [NSWorkspace class])						return	@"delegate canGetProperty failed (2)";
	if (![propertyName isEqualToString:@"sharedWorkspace"])	return	@"delegate canGetProperty failed (3)";

	//
	// Test getting
	//
	customValue = NULL;
	ret = [jsc evalJSString:@"NSWorkspace.sharedWorkspace"];
	if (object != [NSWorkspace class])						return	@"delegate getProperty failed (1)";
	if (![propertyName isEqualToString:@"sharedWorkspace"])	return	@"delegate getProperty failed (2)";
	
	id o = [jsc unboxJSValueRef:ret];
	if (o != [NSWorkspace sharedWorkspace])					return	@"delegate getProperty failed (3)";
	
	//
	// Test custom getting
	//
	customValue = JSValueMakeNumber([jsc ctx], 123);
	ret = [jsc evalJSString:@"NSWorkspace.sharedWorkspace"];
	if (object != [NSWorkspace class])						return	@"delegate getProperty failed (4)";
	if (![propertyName isEqualToString:@"sharedWorkspace"])	return	@"delegate getProperty failed (5)";
	if (JSValueToNumber([jsc ctx], ret, NULL) != 123)		return	@"delegate getProperty failed (6)";
	
	return	nil;
}

- (void) JSCocoa:(JSCocoaController*)controller hadError:(NSString*)error onLineNumber:(NSInteger)lineNumber atSourceURL:(id)url
{
//	NSLog(@"had error");
	hadError = YES;
}


- (BOOL) JSCocoa:(JSCocoaController*)controller canGetProperty:(NSString*)_propertyName ofObject:(id)_object inContext:(JSContextRef)ctx exception:(JSValueRef*)exception;
{
//	NSLog(@"delegate canGet %@(%@).%@", _object, [_object class], _propertyName);
	object			= _object;
	propertyName	= _propertyName;
	return	canGet;
}

- (JSValueRef) JSCocoa:(JSCocoaController*)controller getProperty:(NSString*)_propertyName ofObject:(id)_object inContext:(JSContextRef)ctx exception:(JSValueRef*)exception;
{
//	NSLog(@"delegate get");
	object			= _object;
	propertyName	= _propertyName;
	return	customValue;
}



@end
