/// Copyright (c) 2020 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

class CalendarPickerViewController: UIViewController {
  // MARK: Views
  private lazy var dimmedBackgroundView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
    return view
  }()

  private lazy var collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0

    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.isScrollEnabled = false
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    return collectionView
  }()

  // MARK: Calendar Data Values

  private let selectedDate: Date

  private let selectedDateChanged: ((Date) -> Void)

  private let calendar = Calendar(identifier: .gregorian)

  private lazy var dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "d"
    return dateFormatter
  }()

  // MARK: Initializers

  init(baseDate: Date, selectedDateChanged: @escaping ((Date) -> Void)) {
    self.selectedDate = baseDate
    self.selectedDateChanged = selectedDateChanged

    super.init(nibName: nil, bundle: nil)

    modalPresentationStyle = .overCurrentContext
    modalTransitionStyle = .crossDissolve
    definesPresentationContext = true
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: View Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
  
    collectionView.backgroundColor = .systemGroupedBackground

    view.addSubview(dimmedBackgroundView)
    view.addSubview(collectionView)

    NSLayoutConstraint.activate([
      dimmedBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      dimmedBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      dimmedBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
      dimmedBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      collectionView.leadingAnchor.constraint(
        equalTo: view.readableContentGuide.leadingAnchor),
      collectionView.trailingAnchor.constraint(
        equalTo: view.readableContentGuide.trailingAnchor),

      collectionView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 10),
      collectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5)
    ])
  }
}

private extension CalendarPickerViewController {

  func monthMetadata(for baseDate: Date) -> MonthMetadata? {

      guard let numberOfDaysInMonth = calendar.range(of: .day, in: .month, for: baseDate)?.count,
            let firstDayOfMonth = calendar.date(
              from: calendar.dateComponents([.year, .month], from: baseDate))
      else { return nil }

      let firstDayWeekday = calendar.component(.weekday, from: firstDayOfMonth)

      return MonthMetadata(
        numberOfDays: numberOfDaysInMonth,
        firstDay: firstDayOfMonth,
        firstDayWeekday: firstDayWeekday
      )
  }

  func generateDaysInMonth(for baseDate: Date) -> [Day] {

    guard let metadata = monthMetadata(for: baseDate) else { return [] }
    
    let numberOfDaysInMonth = metadata.numberOfDays
    let offsetInInitialRow = metadata.firstDayWeekday
    let firstDayOfMonth = metadata.firstDay

    print("receive offsetInInitialRow: \(offsetInInitialRow)")
    print("receive firstDayOfMonth: \(offsetInInitialRow)")

    var days: [Day] = (1..<(numberOfDaysInMonth + offsetInInitialRow))
      .map { day in

        // Check current day in loop is within current month or part of previous
        let isWithinDisplayedMonth = day >= offsetInInitialRow

        // Calculate the offset that day is from the first day of month.
        // Value will be negative if the day is from previous month
        let dayOffset = isWithinDisplayedMonth ? day - offsetInInitialRow : -(offsetInInitialRow - day)

        return generateDay(offsetBy: dayOffset, for: firstDayOfMonth, isWithinDisplayedMonth: isWithinDisplayedMonth)
      }

    // append the days of the last row, inclusive of days in next month (if any)
    days += generateStartOfNextMonth(using: firstDayOfMonth)

    return days
  }

  func generateDay(
    offsetBy dayOffset: Int,
    for baseDate: Date,
    isWithinDisplayedMonth: Bool
  ) -> Day {
    let date = calendar.date(byAdding: .day, value: dayOffset, to: baseDate) ?? baseDate

    return Day(
      date: date,
      number: dateFormatter.string(from: date),
      isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
      isWithinDisplayedMonth: isWithinDisplayedMonth
    )
  }

  func generateStartOfNextMonth(
    using firstDayOfDisplayedMonth: Date
  ) -> [Day] {

    // retrieve the last day of the displayed month. Return empty array if fails
    guard let lastDayInMonth = calendar.date(
      byAdding: DateComponents(month: 1, day: -1),
      to: firstDayOfDisplayedMonth)
    else {
      return []
    }

    // calculate the number of extra days needed to fill in last row of calendar month.
    // e.g if last day of month is Sat, result is zero -> return an empty array
    let additionalDays = 7 - calendar.component(.weekday, from: lastDayInMonth)
    guard additionalDays > 0 else { return [] }

    // add additional days in the loop to lastDayInMonth to generate days at beginning of the next month
    let days: [Day] = (1...additionalDays)
      .map { additionalDays in
        generateDay(offsetBy: additionalDays, for: lastDayInMonth, isWithinDisplayedMonth: false)
      }
    
    return days
  }
}
