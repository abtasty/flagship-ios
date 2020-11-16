//
//  ABService.swift
//  Flagship
//
//  Created by Adel on 02/08/2019.
//

import Foundation

//  This class will represent the service , here will be able to post the data



internal class ABService {
    
    var clientId:String!
    
    var visitorId:String?
    
    var anonymousId:String?

    
    private var offLineTracking:FSOfflineTracking!
    
    /// By default
    internal var timeOutServiceForRequestApi = FS_TimeOutRequestApi
    
    // QueueModification
    let serviceQueue = DispatchQueue(label: "com.flagship.queue.service", attributes: .concurrent)
    
    internal var threadSafeOffline:FSOfflineTracking!{
        
          get {
              return serviceQueue.sync {
                
                  offLineTracking
              }
          }
          set {
              serviceQueue.async(flags: .barrier) {
                
                  self.offLineTracking = newValue
              }
          }
      }
    
    /// FSCache Manager
    var cacheManager:FSCacheManager!
    
    
    /// Api Key
    var apiKey:String!
    
    
    /// Session
    internal var sessionService:URLSession = URLSession(configuration: URLSessionConfiguration.default)
    
    
    internal func updateService(_ newVisitorId:String, _ newAnonymousId:String?){
        
        self.visitorId = newVisitorId
        
        self.anonymousId = newAnonymousId
    }
    
    
    
  
    
    
    init(_ clientId:String, _ visitorId:String, _ anonymousId:String, _ apiKey:String, timeoutService:TimeInterval = FS_TimeOutRequestApi) {
        
        
        /// SSet the Client ID
        self.clientId = clientId
        
        
        /// Set visitor
        self.visitorId = visitorId
        
        /// Set anonymousId
        self.anonymousId = anonymousId
        
        
        /// OFFLine Tracking
        offLineTracking = FSOfflineTracking(self)
        
        
        /// Create cache manager
        cacheManager = FSCacheManager()
        
        /// Set Api Key
        self.apiKey = apiKey
        
        /// Set the TimeOut
        self.timeOutServiceForRequestApi = timeoutService
     }
    
    
    func getCampaigns(_ currentContext:Dictionary <String,Any>,  onGetCampaign:@escaping(FSCampaigns?, FlagshipError?)->Void){
        
        do {
            
            let params:NSMutableDictionary = ["visitor_id":visitorId ?? ""  /* , "anonymousId":anonymousId ?? NSNull.self */, "context":currentContext, "trigger_hit":false]
            
            
            print(" @@@@@@@@@@@@@@@@@@@@@@@@@ visitorId =  \(self.visitorId ?? "null")  @@@@@@@@@@@@@@@@@@@@@@@@@")
            
            print(" @@@@@@@@@@@@@@@@@@@@@@@@@ anonymousId =  \(self.anonymousId ?? "null")  @@@@@@@@@@@@@@@@@@@@@@@@@")

            
            let data = try JSONSerialization.data(withJSONObject: params, options:[])
            
            if let getUrl = URL(string:String(format: FSGetCampaigns, clientId)){
                
                var request:URLRequest = URLRequest(url:getUrl, timeoutInterval: timeOutServiceForRequestApi)  //// Request with time interval
                request.httpMethod = "POST"
                request.httpBody = data
                request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                
                /// Add x-api-key
                request.addValue(apiKey, forHTTPHeaderField: FSX_Api_Key)
                
                sessionService.dataTask(with: request) { (responseData, response, error) in
                    
                    if (error == nil){
                        
                        let httpResponse = response as? HTTPURLResponse
                        switch (httpResponse?.statusCode){
                        case 200:
                            
                            if let aResponseData = responseData {
                                
                                do {
                                    
                                    let decoder = JSONDecoder()
                                    let objectDecoded = try decoder.decode(FSCampaigns.self, from: aResponseData)
                                    
                                    // Print Json response
                                    let dico = try JSONSerialization.jsonObject(with: aResponseData, options: .allowFragments)
                                    
                                    FSLogger.FSlog("getCampaigns is : \(dico)", .Campaign)
                                    
                                    /// Save also the data in the Directory
                                    self.cacheManager.saveCampaignsInCache(aResponseData)
                                    onGetCampaign(objectDecoded, nil)
                                    
                                } catch {
                                    
                                    onGetCampaign(nil, FlagshipError.GetCampaignError)
                                }
                            }else{
                                
                                FSLogger.FSlog("responseData is nil when getCampaigns ", .Network)
                                onGetCampaign(nil, FlagshipError.GetCampaignError)
                            }
                            break
                        default:
                            FSLogger.FSlog("Error on get Campaign", .Network)
                            onGetCampaign(nil, FlagshipError.GetCampaignError)
                        }
                    }else{
                        
                        onGetCampaign(nil, FlagshipError.NetworkError)
                    }
                    
                    }.resume()
            }
        }catch{
            
            FSLogger.FSlog("error on serializing json", .Network)
        }
    }
    
    
    // Activate variation
    public func activateCampaignRelativetoKey(_ key:String, _ campaign:FSCampaigns){
        
        // Before send Activate
        // prepare somme actions
        
        guard var infosTrack = campaign.getRelativeInfoTrackForValue(key)else{
            
            FSLogger.FSlog("Failed to send activate .... The key : \(key) doesn't exist", .Campaign)

            return
        }
        
        do {
            // Set Visitor Id
            infosTrack.updateValue(visitorId ?? "" , forKey: "vid")
            
            // Set Client Id
            infosTrack.updateValue(clientId, forKey: "cid")
            
            
            let data = try JSONSerialization.data(withJSONObject: infosTrack, options:[])
            
            // here we have data ready, check the connexion before
            
            if (self.offLineTracking.isConnexionAvailable() == false){
                
                self.offLineTracking.saveActivateEvent(data)
                
                FSLogger.FSlog("Activate will be send in the next lauch when connexion will available", .Network)
                return
            }
            
            if let activateUrl = URL(string:FSActivate) {
                
                var request:URLRequest = URLRequest(url:activateUrl)
                request.httpMethod = "POST"
                request.httpBody = data
                
                /// Add x-api-key
                request.addValue(apiKey, forHTTPHeaderField: FSX_Api_Key)
                
                //let session = URLSession(configuration:URLSessionConfiguration.default)
                sessionService.dataTask(with: request) { (responseData, response, error) in
                      
                      if (error == nil){
                          
                          let httpResponse = response as? HTTPURLResponse
                          
                          switch (httpResponse?.statusCode){
                              
                          case 200,204:
                              
                              FSLogger.FSlog("The activate is sent with success ", .Network)
                              
                              break
                          case 403,400:
                              FSLogger.FSlog("Error On sending activate ", .Network)

                              break
                          default:
                              FSLogger.FSlog("Bad Request", .Network)
                              
                          }
                      }else{
                        
                        FSLogger.FSlog("Fetch failed: \(error?.localizedDescription ?? "Unknown error")" , .Network)
                      }
                      
                      }.resume()
            }
            
        }catch{
            
            FSLogger.FSlog("Bad Request", .Network)

        }
    }
    
}





