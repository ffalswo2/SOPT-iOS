//
//  ShowAttendanceViewModel.swift
//  AttendanceFeature
//
//  Created by devxsby on 2023/04/11.
//  Copyright © 2023 SOPT-iOS. All rights reserved.
//

import Combine

import Core
import Domain
import Foundation

public enum SessionType: String, CaseIterable {
    case noSession = "NO_SESSION"
    case hasAttendance = "HAS_ATTENDANCE"
    case noAttendance = "NO_ATTENDANCE"
}

public final class ShowAttendanceViewModel: ViewModelType {

    // MARK: - Properties
    
    private let useCase: ShowAttendanceUseCase
    private var cancelBag = CancelBag()
    public var sceneType: AttendanceScheduleType?
    
    // MARK: - Inputs
    
    public struct Input {
        let viewDidLoad: Driver<Void>
        let refreshButtonTapped: Driver<Void>
    }
    
    // MARK: - Outputs
    
    public class Output {
        @Published var scheduleModel: AttendanceScheduleModel?
        @Published var scoreModel: AttendanceScoreModel?
    }
    
    // MARK: - init
  
    public init(useCase: ShowAttendanceUseCase) {
        self.useCase = useCase
    }
}

extension ShowAttendanceViewModel {
    
    public func transform(from input: Input, cancelBag: CancelBag) -> Output {
        let output = Output()
        
        self.bindOutput(output: output, cancelBag: cancelBag)
       
        input.viewDidLoad.merge(with: input.refreshButtonTapped)
            .withUnretained(self)
            .sink { owner, _ in
                owner.useCase.fetchAttendanceSchedule()
                owner.useCase.fetchAttendanceScore()
            }.store(in: cancelBag)
    
        return output
    }
  
    private func bindOutput(output: Output, cancelBag: CancelBag) {
        let fetchedSchedule = self.useCase.attendanceScheduleFetched
        let fetchedScore = self.useCase.attendanceScoreFetched
        
        fetchedSchedule.asDriver()
            .sink(receiveValue: { model in
                if model.type != SessionType.noSession.rawValue {
                    self.sceneType = .scheduledDay
                    guard let convertedStartDate = self.convertDateString(model.startDate),
                          let convertedEndDate = self.convertDateString(model.endDate) else { return }

                    let newModel = AttendanceScheduleModel(type: model.type,
                                                           location: model.location,
                                                           name: model.name,
                                                           startDate: convertedStartDate,
                                                           endDate: convertedEndDate,
                                                           message: model.message,
                                                           attendances: model.attendances)
                    output.scheduleModel = newModel
                } else {
                    self.sceneType = .unscheduledDay
                    output.scheduleModel = model
                }
            })
            .store(in: cancelBag)
        
        fetchedScore.asDriver()
            .sink(receiveValue: { model in
                output.scoreModel = model
            })
            .store(in: cancelBag)
    }
    
    private func convertDateString(_ dateString: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        guard let date = dateFormatter.date(from: dateString) else { return nil }
        
        dateFormatter.dateFormat = "M월 d일 EEEE H:mm"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return dateFormatter.string(from: date)
    }
    
    func formatTimeInterval(startDate: String, endDate: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M월 d일 EEEE HH:mm"
        
        guard let startDateObject = dateFormatter.date(from: startDate),
              let endDateObject = dateFormatter.date(from: endDate) else { return nil }
        
        let formattedStartDate = dateFormatter.string(from: startDateObject)
        
        dateFormatter.dateFormat = "HH:mm"
        let formattedEndDate = dateFormatter.string(from: endDateObject)
        
        return "\(formattedStartDate) ~ \(formattedEndDate)"
    }
}
