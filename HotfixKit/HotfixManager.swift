//
//  HotfixManager.swift
//  HotfixKit
//
//  Created by Johan Kool on 12/12/14.
//  Copyright (c) 2014 Koolistov Pte. Ltd. All rights reserved.
//

import Foundation

/*
    Sample hotfix dictionary:

    {
        "AppVersion": "1.0",
        "OSVersion": "8.0.1",
        "InterfaceIdiom": "pad",
        "Class": "MainViewController",
        "Selector": "doSomethingBuggy:",
        "MethodType": "instance",
        "ReplacementSelector": "return-object",
        "ReplacementReturnValue": true,
        "Alert": {
                    "Title": "Sorry, temporarily disabled",
                    "Message": "This feature is temporarily disabled while we work on a fix.",
                    "Buttons": [{
                                    "Title": "Cancel"
                                }, 
                                {
                                    "Title": "Read More"
                                    "Action": "http://example.com/readmore"
                                }]
                  }
    }
*/


public enum Key: String {
    case AppVersion = "AppVersion"
    case OSVersion = "OSVersion"
    case InterfaceIdiom = "InterfaceIdiom"
    case Class = "Class"
    case Selector = "Selector"
    case MethodType = "MethodType"
    case ReplacementSelector = "ReplacementSelector"
    case ReplacementReturnValue = "ReplacementReturnValue"
    case Alert = "Alert"
    case Title = "Title"
    case Message = "Message"
    case Buttons = "Buttons"
    case Action = "Action"
}

public enum MethodType: String {
    case Instance = "instance"
    case Class = "class"
}

public enum ReplacementSelector: String {
    case ReturnObject = "return-object"
}

class Hotfix {
    let appVersion: String?
    let osVersion: String?
    let interfaceIdiom: UIUserInterfaceIdiom?
    let targetClass: AnyClass!
    let selector: String!
    let methodType: MethodType!
    let replacementSelector: ReplacementSelector!
    let replacementReturnValue: AnyObject!
    let alert: HotfixAlert?

    init?(hotfix: NSDictionary) {
        let appVersion: AnyObject? = hotfix[Key.AppVersion.rawValue]
        if let appVersion = appVersion as? String {
            self.appVersion = appVersion
        } else if appVersion != nil {
            println("AppVersion is not a string")
            return nil
        }

        let osVersion: AnyObject? = hotfix[Key.OSVersion.rawValue]
        if let osVersion = osVersion as? String {
            self.osVersion = osVersion
        } else if osVersion != nil {
            println("OSVersion is not a string")
            return nil
        }

        let interfaceIdiom: AnyObject? = hotfix[Key.InterfaceIdiom.rawValue]
        if let interfaceIdiom = interfaceIdiom as? String {
            switch interfaceIdiom {
            case "pad", "ipad", "iPad":
                self.interfaceIdiom = .Pad
            case "phone", "iphone", "iPhone":
                self.interfaceIdiom = .Phone
            default:
                println("InterfaceIdiom has unexpected string value")
                return nil
            }
        } else if interfaceIdiom != nil {
            println("InterfaceIdiom is not a string")
            return nil
        }

        if let classString = hotfix[Key.Class.rawValue] as? String {
            self.targetClass = NSClassFromString(classString)
            if self.targetClass == nil {
                println("No class found named \(classString)")
                return nil
            }
        } else {
            println("Class is missing or not a string")
            return nil
        }

        let selector: AnyObject? = hotfix[Key.Selector.rawValue]
        if let selector = selector as? String {
            self.selector = selector
        } else if selector != nil {
            println("Selector is not a string")
            return nil
        }

        let methodType: AnyObject? = hotfix[Key.MethodType.rawValue]
        if let methodType = methodType as? String {
            self.methodType = MethodType(rawValue: methodType)
        }
        if self.methodType == nil {
            self.methodType = .Instance
        }

        let replacementSelector: AnyObject? = hotfix[Key.ReplacementSelector.rawValue]
        if let replacementSelector = replacementSelector as? String {
            self.replacementSelector = ReplacementSelector(rawValue: replacementSelector)
        }
        if self.replacementSelector == nil {
            self.replacementSelector = .ReturnObject
        }

        self.replacementReturnValue = hotfix[Key.ReplacementReturnValue.rawValue]
    }
}

struct HotfixAlert {
    let title: String?
    let message: String?
    let buttons: [HotfixAlertButton] = []
}

struct HotfixAlertButton {
    let title: String
    let action: NSURL?
}

private let sharedHotfixManager = HotfixManager()

public class HotfixManager: NSObject {

    private var activeHotfixes: [Hotfix] = []

    public class func activateHotfixes(hotfixDicts: [NSDictionary]) {
        sharedHotfixManager.activateHotfixes(hotfixDicts)
    }

    public class func deactivateHotfixes() {
        sharedHotfixManager.deactivateHotfixes()
    }

    func activateHotfixes(hotfixDicts: [NSDictionary]) {
        for hotfixDict in hotfixDicts {
            if let hotfix = Hotfix(hotfix: hotfixDict) {
                if isApplicableHotfix(hotfix) {
                    if activateHotfix(hotfix) {
                        println("Hotfix activated")
                        activeHotfixes.append(hotfix)
                    } else {
                        println("Hotfix could not be activated")
                    }
                } else {
                    println("Hotfix not applicable")
                }
            } else {
                println("Hotfix invalid/incomplete")
            }
        }
    }

    func deactivateHotfixes() {
        for hotfix in activeHotfixes {
            deactivateHotfix(hotfix)
        }
        activeHotfixes.removeAll(keepCapacity: true)
    }

    private func isApplicableHotfix(hotfix: Hotfix) -> Bool {
        if let hotfixAppVersion = hotfix.appVersion {
            let appVersion = "1.0" // TODO: Get actual app version
            if hotfixAppVersion != appVersion {
                println("Hotfix app version \(hotfixAppVersion) does not match app version \(appVersion)")
                return false
            }
        }

        if let hotfixOSVersion = hotfix.osVersion {
            let osVersion = "8.1" // TODO: Get actual OS version
            if hotfixOSVersion != osVersion {
                println("Hotfix OS version \(hotfixOSVersion) does not match OS version \(osVersion)")
                return false
            }
        }

        if let hotfixInterfaceIdiom = hotfix.interfaceIdiom {
            let interfaceIdiom = UIDevice.currentDevice().userInterfaceIdiom
            if hotfixInterfaceIdiom != interfaceIdiom {
                println("Hotfix interface idiom does not match")
                return false
            }
        }

        return true
    }

    private func activateHotfix(hotfix: Hotfix) -> Bool {
        var replacementSelector: String?
        switch hotfix.replacementSelector! {
        case .ReturnObject:
            replacementSelector = "hotfixPlaceholder\(countElements(activeHotfixes))"
        }
        switch hotfix.methodType! {
        case .Instance:
            return swizzleInstanceMethodSelector(hotfix.selector, inClass: hotfix.targetClass, replacementSelector: replacementSelector!)
        case .Class:
            return swizzleClassMethodSelector(hotfix.selector, inClass: hotfix.targetClass, replacementSelector: replacementSelector!)
        }
    }

    private func deactivateHotfix(hotfix: Hotfix) -> Bool {
        return false
    }

    private func swizzleInstanceMethodSelector(originalSelector: String, inClass: AnyClass, replacementSelector: String) -> Bool {
        let originalMethod: Method? = class_getInstanceMethod(inClass, Selector(stringLiteral: originalSelector))
        let replacementMethod: Method? = class_getInstanceMethod(inClass, Selector(stringLiteral: replacementSelector))

        if originalMethod != nil && replacementMethod != nil {
            method_exchangeImplementations(originalMethod!, replacementMethod!)
            return true
        }
        return false
    }

    private func swizzleClassMethodSelector(originalSelector: String, inClass: AnyClass, replacementSelector: String) -> Bool {
        let originalMethod: Method? = class_getClassMethod(inClass, Selector(stringLiteral: originalSelector))
        let replacementMethod: Method? = class_getClassMethod(inClass, Selector(stringLiteral: replacementSelector))

        if originalMethod != nil && replacementMethod != nil {
            method_exchangeImplementations(originalMethod!, replacementMethod!)
            return true
        }
        return false
    }

    func performHotfixReplacementAtIndex(index: Int) -> AnyObject? {
        let hotfix = activeHotfixes[index]
        return hotfix.replacementReturnValue
    }

}


public extension NSObject {

    func hotfixPlaceholder0() -> AnyObject? {
        return sharedHotfixManager.performHotfixReplacementAtIndex(0)
    }

    func hotfixPlaceholder1() -> AnyObject? {
        return sharedHotfixManager.performHotfixReplacementAtIndex(1)
    }

    func hotfixPlaceholder2() -> AnyObject? {
        return sharedHotfixManager.performHotfixReplacementAtIndex(2)
    }

    // TODO: Define more placeholders!

}
