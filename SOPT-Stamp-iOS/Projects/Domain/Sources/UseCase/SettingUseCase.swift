//
//  SettingUseCase.swift
//  Presentation
//
//  Created by 양수빈 on 2022/12/17.
//  Copyright © 2022 SOPT-Stamp-iOS. All rights reserved.
//

import Combine

import Core

public protocol SettingUseCase {
    func resetStamp()
    var resetSuccess: PassthroughSubject<Bool, Error> { get set }
}

public class DefaultSettingUseCase {
  
    private let repository: SettingRepositoryInterface
    private var cancelBag = CancelBag()
    
    public var resetSuccess = PassthroughSubject<Bool, Error>()
  
    public init(repository: SettingRepositoryInterface) {
        self.repository = repository
    }
}

extension DefaultSettingUseCase: SettingUseCase {
    public func resetStamp() {
        repository.resetStamp()
            .sink { success in
                self.resetSuccess.send(success)
            }.store(in: self.cancelBag)
    }
}