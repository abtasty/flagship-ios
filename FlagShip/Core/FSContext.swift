//
//  FSContext.swift
//  Flagship
//
//  Created by Adel on 05/08/2019.
//

import Foundation



public class FSContext{
    
    
    // Dictionary that represent all keys value according to context users
    internal var currentContext:Dictionary <String, Any>! // by Default the context is empty
    
    // All modification from server 
    private var currentModification:Dictionary <String, Any>
    
    
    public init(){
        
        self.currentContext = Dictionary()
        
        self.currentModification = Dictionary()
    }
    
    
    
    public func updateModification(_ campaignsObject:FSCampaigns?){
        
        // Clean all curent modification before
        
        self.currentModification.removeAll()
        
        for item:FSCampaign in campaignsObject?.campaigns ?? []{
            
            self.currentModification.merge((item.variation?.modifications!.value)!) {  (_, new) in new }            
        }
    }
    
    
    ////////////////// BOOL ///////////////////////////////
    // Add Bool Key / value
    public func  addBoolenCtx(_ key:String, _ bool:Bool){
        
        self.currentContext.updateValue(bool, forKey: key)
    }

    
    ////////////////// STRING ///////////////////////////////
    
    // Add String Key / value
    public func  addStringCtx(_ key:String, _ valueString:String){
        
        self.currentContext.updateValue(valueString, forKey: key)

      //  self.currentContext.setValue(valueString, forKey: key)

    }
 
    ////////////////// Double ///////////////////////////////
    
    // Add Bool Key / value
    public func  addDoubleCtx(_ key:String, _ valueDouble:Double){
        
        self.currentContext.updateValue(valueDouble, forKey: key)
    }
    
    
    /////////////////// FLoat //////////////////////////////////
    
    public func  addFloatCtx(_ key:String, _ valueFlaot:Float){
        
        self.currentContext.updateValue(valueFlaot, forKey: key)
    }
    
    
    //////////////// Int ////////////////////////////////////////
    
    public func  addIntCtx(_ key:String, _ valueInt:Int){
        
        self.currentContext.updateValue(valueInt, forKey: key)
    }
    
    
    
    /////  Read Values ////////////
    
    // Read Boolean
    public func readBooleanFromContext(_ key:String, defaultBool:Bool)->Bool{
 
        return currentModification[key, default: defaultBool] as! Bool
    }
    
    
    //  Read String
    public func readStringFromContext(_ key:String, defaultString:String)->String{
        
        return currentModification[key, default: defaultString] as! String

    }
    
    
    /// Read Double
    public func readDoubleFromContext(_ key:String, defaultDouble:Double)->Double{
        
        return currentModification[key, default: defaultDouble] as! Double

    }
    
    
    /// Float
    public func readFloatFromContext(_ key:String, defaultFloat:Float)->Float{
        
        return currentModification[key, default: defaultFloat] as! Float
        
    }
    
    // Int
    public func readIntFromContext(_ key:String, defaultInt:Int)->Int{
        
        return currentModification[key, default: defaultInt] as! Int
        
    }
    
    //////////////// Remove   &   Clean   ///////////////////////
   
    public func  removeKeyFromContext(_ key:String){
        
        self.currentContext.removeValue(forKey: key)
        
    }
    
    // Remove All values from context
    
    public func CleanContext(){
        
        self.currentContext.removeAll()
    }
    
}
