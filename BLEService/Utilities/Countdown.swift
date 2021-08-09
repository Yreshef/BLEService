//
//  Countdown.swift
//  BLEService
//
//  Created by Yohai Reshef on 04/08/2021.
//

import Foundation

///Timer wrapper that automatically invalidates when released
 class Countdown {
  let timer: Timer
  
  init(seconds: TimeInterval, closure: @escaping () -> ()) {
    timer = Timer.scheduledTimer(withTimeInterval: seconds,
                                 repeats: false,
                                 block: { _ in
                                  closure()
                                 })
  }
  deinit {
    timer.invalidate()
  }
}
