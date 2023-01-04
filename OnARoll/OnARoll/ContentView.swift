//
//  ContentView.swift
//  OnARoll
//
//  Created by hunter downey on 1/24/22.
//

import SwiftUI

struct ContentView: View {
    let diceTypes = [4, 6, 8, 10, 12, 20, 100]
    
    @AppStorage("selectedDiceType") var selectedDiceType = 6
    @AppStorage("numberToROll") var numberToRoll = 4
    
    @State private var currentResult = DiceResult(type: 0, number: 0)
    
    let columns: [GridItem] = [
        .init(.adaptive(minimum: 60))
    ]
    
    let timer = Timer.publish(every: 0.1, tolerance: 0.1, on: .main, in: .common).autoconnect()
    @State private var stoppedDice = 0
    
    @State private var feedback = UIImpactFeedbackGenerator(style: .light)
    
    let savePath = FileManager.documentsDirectory.appendingPathComponent("SavedRolls.json")
    @State private var savedResults = [DiceResult]()
    
    @Environment(\.accessibilityVoiceOverEnabled) var voiceOverEnabled
    
    init() {
        let colorApp = UINavigationBarAppearance()
        colorApp.titleTextAttributes = [.foregroundColor: UIColor(red: 255/255, green: 45/255, blue: 0/255, alpha: 1.0)]
        UINavigationBar.appearance().standardAppearance = colorApp
        UINavigationBar.appearance().scrollEdgeAppearance = colorApp
        UINavigationBar.appearance().barTintColor = UIColor(red: 238/255, green: 238/255, blue: 238/255, alpha: 1.0)
        UINavigationBar.appearance().tintColor = UIColor(red: 238/255, green: 238/255, blue: 238/255, alpha: 1.0)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                ScrollView {
                    Section {
                        Picker("Type of dice", selection: $selectedDiceType) {
                            ForEach(diceTypes, id: \.self) { type in
                                Text("\(type)")
                                    .foregroundColor(Color(hex: 0xff2d00))
                            }
                            .foregroundColor(Color(hex: 0xff2d00))
                        }
                        .pickerStyle(.segmented)
                        .foregroundColor(Color(hex: 0xff2d00))
                        
                        Stepper("Number of dice: \(numberToRoll)", value: $numberToRoll, in: 1...20)
                            .foregroundColor(Color(hex: 0xeeeeee))
                        
                    } footer: {
                        LazyVGrid(columns: columns) {
                            ForEach(0..<currentResult.rolls.count, id: \.self) { rollNumber in
                                Text(String(currentResult.rolls[rollNumber]))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .aspectRatio(1, contentMode: .fit)
                                    .foregroundColor(Color(hex: 0xeeeeee))
                                    .background(Color(hex: 0xff2d00))
                                    .cornerRadius(10)
                                    .shadow(radius: 3)
                                    .font(.title2)
                                    .padding(5)
                            }
                        }
                    }
                    .disabled(stoppedDice < currentResult.rolls.count)
                    .accessibilityElement()
                    .accessibilityLabel("Latest roll: \(currentResult.description)")
                    
                    Button("Roll it!", action: rollDice)
                        .frame(width: 100, height: 50)
                        .background(Color(hex: 0xeeeeee))
                        .foregroundColor(Color(hex: 0xff2d00))
                    
                    if savedResults.isEmpty == false {
                        Section("Previous results") {
                            ForEach(savedResults) { result in
                                VStack(alignment: .leading) {
                                    Text("\(result.number) x D\(result.type)")
                                        .font(.headline)
                                    
                                    Text(result.description)
                                }
                                .accessibilityElement()
                                .accessibilityLabel("\(result.number) D\(result.type), \(result.description)")
                            }
                        }
                    }
                }
                .navigationTitle("On A Roll")
                .navigationBarTitleDisplayMode(.inline)
                .onReceive(timer) { date in
                    updateDice()
                }
                .onAppear(perform: load)
            }
        }
    }
    
    func rollDice() {
        currentResult = DiceResult(type: selectedDiceType, number: numberToRoll)
        
        if voiceOverEnabled {
            stoppedDice = numberToRoll
            savedResults.insert(currentResult, at: 0)
            save()
        } else {
            stoppedDice = -20
        }
    }
    
    func updateDice() {
        guard stoppedDice < currentResult.rolls.count else { return }
        
        for i in stoppedDice..<numberToRoll {
            if i < 0 { continue }
            currentResult.rolls[i] = Int.random(in: 1...selectedDiceType)
            feedback.impactOccurred()
        }
        
        stoppedDice += 1
        
        if stoppedDice == numberToRoll {
            savedResults.insert(currentResult, at: 0)
            save()
        }
    }
    
    func load() {
        if let data = try? Data(contentsOf: savePath) {
            if let results = try? JSONDecoder().decode([DiceResult].self, from: data) {
                savedResults = results
            }
        }
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(savedResults) {
            try? data.write(to: savePath, options: [.atomic, .completeFileProtection])
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
