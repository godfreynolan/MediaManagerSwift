//
//  AlertView.swift
//  MediaManagerDemo
//
//  Created by Samuel Scherer on 4/14/21.
//  Copyright © 2021 DJI. All rights reserved.
//

import Foundation
import UIKit

//TODO: use typealiases
//typedef void (^DJIAlertViewActionBlock)(NSUInteger buttonIndex);
//typealias DJIAlertViewActionBlock = Int ->
//typedef void (^DJIAlertInputViewActionBlock)(NSArray<UITextField*>* _Nullable textFields, NSUInteger buttonIndex);
//#define NavControllerObject(navController) UINavigationController* navController = (UINavigationController*)[[UIApplication sharedApplication] keyWindow].rootViewController;

//
//-(void) updateMessage:(nullable NSString *)message;



class AlertView: NSObject {
    
    var alertController : UIAlertController?

    //+(instancetype _Nullable) showAlertViewWithMessage:(NSString* _Nullable)message titles:(NSArray<NSString*> * _Nullable)titles action:(DJIAlertViewActionBlock _Nullable)actionBlock;
    public class func showAlertWith(message:String, titles:[String]?, actionClosure:((Int)->())?) -> AlertView {
        //    DJIAlertView* alertView = [[DJIAlertView alloc] init];
        let alertView = AlertView()
        //    alertView.alertController = [UIAlertController alertControllerWithTitle:@"" message:message preferredStyle:UIAlertControllerStyleAlert];
        alertView.alertController = UIAlertController(title: "", message: message, preferredStyle: UIAlertController.Style.alert)
        
        if let titles = titles {
            for title in titles {
                let actionStyle : UIAlertAction.Style = (titles.firstIndex(of: title) == 0) ? .cancel : .default
                let alertAction = UIAlertAction(title: title, style: actionStyle) { (action:UIAlertAction) in
                    //TODO: maybe use titles.firstIndex{$0 === title} because it checks class identity
                    // https://stackoverflow.com/questions/24028860/how-to-find-index-of-list-item-in-swift
                    if let actionClosure = actionClosure, let titleIndex = titles.firstIndex(of: title) {
                        actionClosure(titleIndex)
                    }
                }
                alertView.alertController?.addAction(alertAction)
            }
        }
        //#define NavControllerObject(navController) UINavigationController* navController = (UINavigationController*)[[UIApplication sharedApplication] keyWindow].rootViewController;
        //    NavControllerObject(navController);
        if let navController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
            if let alertController = alertView.alertController {
                navController.present(alertController, animated: true, completion: nil)
            }
        }
        return alertView
    }
    
    //+(instancetype _Nullable) showAlertViewWithMessage:(NSString* _Nullable)message titles:(NSArray<NSString*> * _Nullable)titles textFields:(NSArray<NSString*>* _Nullable)textFields action:(DJIAlertInputViewActionBlock _Nullable)actionBlock;
    public class func showAlertWith(message:String, titles:[String]?, textFields:[String]?, actionClosure:((Int)->())?) -> AlertView  {
        //    DJIAlertView* alertView = [[DJIAlertView alloc] init];
        let alertView = AlertView()
        //
        //    alertView.alertController = [UIAlertController alertControllerWithTitle:@"" message:message preferredStyle:UIAlertControllerStyleAlert];
        //    for (NSUInteger index = 0; index < textFields.count; ++index) {
        //        [alertView.alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        //            textField.placeholder = textFields[index];
        //        }];
        //    }
        alertView.alertController = UIAlertController(title: "", message: message, preferredStyle: UIAlertController.Style.alert)
        if let textFields = textFields {
            for textFieldText in textFields {
                alertView.alertController?.addTextField(configurationHandler: { (textField:UITextField) in
                    textField.placeholder = textFieldText
                })
            }
        }

        //
        //    NSArray* fieldViews = alertView.alertController.textFields;
        //    for (NSUInteger index = 0; index < titles.count; ++index) {
        //        UIAlertActionStyle actionStyle = (index == 0) ? UIAlertActionStyleCancel : UIAlertActionStyleDefault;
        //        UIAlertAction* alertAction = [UIAlertAction actionWithTitle:titles[index] style:actionStyle handler:^(UIAlertAction * _Nonnull action) {
        //            if (actionBlock) {
        //                actionBlock(fieldViews, index);
        //            }
        //        }];
        //
        //        [alertView.alertController addAction:alertAction];
        //    }
        
        //TODO: verify this actually matches the loop from the above method...
        if let titles = titles {
            for title in titles {
                let actionStyle : UIAlertAction.Style = (titles.firstIndex(of: title) == 0) ? .cancel : .default
                let alertAction = UIAlertAction(title: title, style: actionStyle) { (action:UIAlertAction) in
                    //TODO: maybe use titles.firstIndex{$0 === title} because it checks class identity
                    // https://stackoverflow.com/questions/24028860/how-to-find-index-of-list-item-in-swift
                    if let actionClosure = actionClosure, let titleIndex = titles.firstIndex(of: title) {
                        actionClosure(titleIndex)
                    }
                }
                alertView.alertController?.addAction(alertAction)
            }
        }
        //
        //    NavControllerObject(navController);
        //    [navController presentViewController:alertView.alertController animated:YES completion:nil];
        if let navController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController {
            if let alertController = alertView.alertController {
                navController.present(alertController, animated: true, completion: nil)
            }
        }
        return alertView
    }
    
    @objc public func dismissAlertView() {
        self.alertController?.dismiss(animated: true, completion: nil)
        

    }
    
    @objc public func update(message:String) {
        self.alertController?.message = message
    }
}
