# FlexLib

[![CI Status](http://img.shields.io/travis/zhenglibao/FlexLib.svg?style=flat)](https://travis-ci.org/zhenglibao/FlexLib)
[![Version](https://img.shields.io/cocoapods/v/FlexLib.svg?style=flat)](http://cocoapods.org/pods/FlexLib)
[![License](https://img.shields.io/cocoapods/l/FlexLib.svg?style=flat)](http://cocoapods.org/pods/FlexLib)
[![Platform](https://img.shields.io/cocoapods/p/FlexLib.svg?style=flat)](http://cocoapods.org/pods/FlexLib)

## FlexLib
[中文版](https://github.com/zhenglibao/FlexLib/blob/master/README.zh.md)

FlexLib is an obj-c layout framework for iOS. It's based on [flexbox](https://css-tricks.com/snippets/css/a-guide-to-flexbox/) model which is standard for web layout. So the layout capability is powerful and easy to use.

With FlexLib, you can write iOS ui much faster than before, and there are better adaptability.

- [Screenshots](#screenshots)
- [Feature](#feature)
- [Usage](#usage)
- [Hot Preview](#hot-preview)
- [Usage For Swift Project](#usage-for-swift-project)
- [Example](#example)
- [Attribute Reference](#attribute-reference)
- [Installation](#installation)
- [About Flexbox](#about-flexbox)
- [FAQ](#faq)
- [Author](#author)
- [License](#license)

---

## Screenshots

This demo is hot preview:

![example0](https://raw.githubusercontent.com/zhenglibao/FlexLib/master/Doc/hotpreview2.gif)

Can you imagine you almost need nothing code to implement the following effect?

![example1](https://raw.githubusercontent.com/zhenglibao/FlexLib/master/Doc/scrollview.gif)
![example2](https://raw.githubusercontent.com/zhenglibao/FlexLib/master/Doc/modelview.gif)
![example3](https://raw.githubusercontent.com/zhenglibao/FlexLib/master/Doc/textview.gif)

iPhoneX adaption

![iPhoneX](https://raw.githubusercontent.com/zhenglibao/FlexLib/master/Doc/tableview.gif)


---

## Feature
* layout based on xml format
* auto variable binding
* onPress event binding
* support layout attribute (padding/margin/width/...)
* support view attribute (eg: bgColor/fontSize/...)
* support reference predefined style
* view attributes extensible
* support modal view
* table cell height calculation
* support iPhoneX perfectly
* support hot preview
* auto adjust view to avoid keyboard
* keyboard toolbar to switch input field
* cache support for release mode
* support Swift project
* view all layouts in one page (Control+V)

---

## Usage

### Use xml layout file for ViewController:

* Write layout with xml file. The following is a demo file:

```xml
<UIView layout="flex:1,justifyContent:center,alignItems:center" attr="bgColor:lightGray">
    <UIView layout="height:1,width:100%" attr="bgColor:red"/>
    <FlexScrollView name="_scroll" layout="flex:1,width:100%,alignItems:center" attr="vertScroll:true">
        <UILabel name="_label" attr="@:system/buttonText,text:You can run on iPhoneX,color:blue"/>
        <UIView onPress="onTest:" layout="@:system/button" attr="bgColor:#e5e5e5">
            <UILabel attr="@:system/buttonText,text:Test ViewController"/>
        </UIView>
        <UIView onPress="onTestTable:" layout="@:system/button" attr="bgColor:#e5e5e5">
            <UILabel attr="@:system/buttonText,text:Test TableView"/>
        </UIView>
        <UIView onPress="onTestScrollView:" layout="@:system/button" attr="bgColor:#e5e5e5">
            <UILabel attr="@:system/buttonText,text:Test ScrollView"/>
        </UIView>
        <UIView onPress="onTestModalView:" layout="@:system/button" attr="bgColor:#e5e5e5">
            <UILabel attr="@:system/buttonText,text:Test ModalView"/>
        </UIView>
        <UIView onPress="onTestLoginView:" layout="@:system/button" attr="bgColor:#e5e5e5">
            <UILabel attr="@:system/buttonText,text:Login Example"/>
        </UIView>
    </FlexScrollView>
</UIView>
```

* Derive view controller class from FlexBaseVC

```objective-c

@interface FlexViewController : FlexBaseVC
@end

```

```objective-c

@interface FlexViewController ()
{
    // these will be binded to those control with same name in xml file
    FlexScrollView* _scroll;
    UILabel* _label;
}
@end

@implementation FlexViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"FlexLib Demo";
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)onTest:(id)sender {
    TestVC* vc=[[TestVC alloc]init];
    [self presentViewController:vc animated:YES completion:nil];
}
- (void)onTestTable:(id)sender {
    TestTableVC* vc=[[TestTableVC alloc]init];
    [self presentViewController:vc animated:YES completion:nil];
}

@end

```
* Now you can use the controller as normal:
```objective-c

    FlexViewController *vc = [[FlexViewController alloc] init];

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    self.window.rootViewController = nav;

    [self.window makeKeyAndVisible];

```

### Use xml layout file for TableCell:

* Write layout with xml file. There is no difference than view controller layout except that it will be used for tabel cell.

* Derive table cell class from FlexBaseTableCell:

```objective-c

@interface TestTableCell : FlexBaseTableCell
@end

```

```objective-c

@interface TestTableCell()
{
    UILabel* _name;
    UILabel* _model;
    UILabel* _sn;
    UILabel* _updatedBy;

    UIImageView* _return;
}
@end
@implementation TestTableCell
@end

```

* In cellForRowAtIndexPath callback, call initWithFlex to build cell. In heightForRowAtIndexPath, call heightForWidth to calculate height

```objective-c

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {

    static NSString *identifier = @"TestTableCellIdentifier";
    TestTableCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[TestTableCell alloc]initWithFlex:nil reuseIdentifier:identifier];
    }
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(_cell==nil){
        _cell = [[TestTableCell alloc]initWithFlex:nil reuseIdentifier:nil];
    }
    return [_cell heightForWidth:_table.frame.size.width];
}

```

### Use xml layout file for other view:

* Write layout xml file.

* Use FlexRootView to load xml file, then set attribute to make it have flexible width or height

* add this FlexRootView as child view to other normal parent view

---

## Hot preview
### Hot preview for view controller
* start http server in your local folder

    For mac with python2.7 installed:

    open Terminal and go to your folder, then input:

    python -m SimpleHTTPServer 8000

* Set preview base url, call like this:

    FlexSetPreviewBaseUrl(@"http://192.168.6.104:8000/FlexLib/res/");

* Run your project, you can press Cmd+R to reload the layout on simulator. Notice: this shortcut is available only on debug mode.

**Notice: Cmd+R should be pressed on simulator when view controller is shown, not in XCode. The base url will be used to concate the resource url. For example, if the base url is 'http://ip:port/abc/' and you want to access flex resource 'TestVC', then your final url will be 'http://ip:port/abc/TestVC.xml'**


### hot preview for any ui

* Start http server in your local folder as before

* Set preview base url

* Set resource load way
    FlexSetLoadFunc(YES) or
    FlexSetCustomLoadFunc(loadfunc)

### Set preview parameter without modify your code everytime (Debug mode only)
* Press Cmd+D when any view controller based on FlexBaseVC is shown
* Set all parameters then save.
* Call FlexRestorePreviewSetting when app init. This will restore all setting.
---
## Usage For Swift Project
* Adjust 'Podfile' to use frameworks

![podfile](https://raw.githubusercontent.com/zhenglibao/FlexLib/master/Doc/res/podfile.png)

* Extend your swift class from FlexBaseVC, FlexBaseTableCell, etc
* For those variables, onPress events, class, you should declare them with @objc keyword. Like this:

![@objc](https://raw.githubusercontent.com/zhenglibao/FlexLib/master/Doc/res/atobjc.png)


---

## Example

To run the example project, clone the repo, and open `Example/FlexLib.xcworkspace` with XCode to run.

---

## Attribute Reference

Layout attributes are stable, but view attributes are still in rapid increased. You can search FLEXSET in the library to find all supported view attributes. And you can make extendsion in your project by the catagory to support more view attributes.

**Notice: FlexLib will output log when it doesn't recognize the attribute you provided. So you should not ignore the log when you develop your project.**

 [layout attributes](https://github.com/zhenglibao/FlexLib/blob/master/Doc/layout.md)
 
 [view attributes](https://github.com/zhenglibao/FlexLib/blob/master/Doc/viewattr.md)
 
---

## Installation

FlexLib is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'FlexLib'
```

---

## FAQ

### Cmd+R or Cmd+D not work
Please check your simulator setting:
goto "Hardware -> Keyboard", checked "Use the Same Keyboard as
macOS" and "Connect Hardware keyboard"
If still not work, please restart your simulator and Xcode.

### Cmd+R shortcut works, but ui not refresh
Please check your simulator network, make sure your mac http server is accessible on safari.

Possible reasons & solutions:
* proxy or vpn has been set, you need to close it.
* In iOS system settings -> Developer -> Allow HTTP Services
* App http access was not allowed by default. You must turn on it.
* Maybe iOS simulator need restart.
* Turn off wifi, then turn on it.

---

## About Flexbox
[CSS-flexbox](https://css-tricks.com/snippets/css/a-guide-to-flexbox/)

[Yoga-flexbox](https://facebook.github.io/yoga/docs/flex-direction/)

---

## Author

zhenglibao, 798393829@qq.com. QQ qun: 687398178

You can contact me if you have any problem.

I hope you will like and star it. :)

---

## License

FlexLib is available under the MIT license. See the LICENSE file for more info.

---

