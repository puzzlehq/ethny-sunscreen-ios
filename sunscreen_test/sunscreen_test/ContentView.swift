//
//  ContentView.swift
//  sunscreen_test
//
//  Created by Darvish Kamalia on 9/23/23.
//

import SwiftUI

struct Keys {
    let publicKey: String
    let privateKey: String
}


var contractAddress: String = "71c605380fc616dd0c5e04fadaa06a475cc52b98"
let ethWalletPrivate = "da193f9ad32464f2ca6fa73595ab52e719aa0a81e4d57cfbd390b940e955e8af"

struct Item {
    let name: String
    var tally: Double
}

struct ContentView: View {
    @State var keys: Keys?
    @State var items: [Item] = []
    @State var newItemName = ""
    @State var refreshing = false
    
    var body: some View {
        VStack(spacing: 10) {
            if let keys = keys {
                Text("Loaded wallet ")
                
                if refreshing {
                    Text("Refreshing counts")
                        .background(Color.blue)
                        .foregroundColor(.white)
                }
                
//                Button("Deploy contract") {
//                    Task {
//                        let result = await deployContract(publicKey: keys.publicKey, privateKey: keys.privateKey, walletKey: ethWalletPrivate)
//                        print("Deployed at \(result)")
//                        contractAddress = result
//                    }
//                }
                
                TextField("Add a new item!", text: $newItemName)
                AsyncButton("Add item") {
                    let result = addProposal(contractAddress: contractAddress, name: newItemName, contents: "this is a test proposal", publicKey: keys.publicKey, privateKey: keys.privateKey, walletKey: ethWalletPrivate)
                    print(result)
                    refreshItems()
                    newItemName = ""
                }
                
                AsyncButton("Get items") {
                   refreshItems()
                }
                
                ForEach(Array(items.enumerated()), id: \.offset) { index, proposal in
                    HStack {
                        Text(proposal.name)
                        Spacer()
                        Text("\(proposal.tally.rounded())")
                        AsyncButton(systemImageName: "plus.circle", action: {
                            var inputs = Array(repeating: UInt64(0), count: items.count)
                            inputs[index] = 1
                            let _ = submitVotes(contractAddress: contractAddress, publicKey: keys.publicKey, privateKey: keys.privateKey, walletKey: ethWalletPrivate, votes: inputs)
                            refreshTallies()
                        })
                    }
                }
                
                Button("Refresh tallies") {
                    Task {
                        refreshTallies()
                    }
                }
                
            } else {
                VStack {
                    Image(systemName: "globe")
                        .imageScale(.large)
                        .foregroundColor(.accentColor)
                    Text("Generate keys")
                }
                .padding()
                .onAppear {
                    Task {
                        let generated = generateKeysLocal()
                        let wallet = await tryWallet(privateKey: ethWalletPrivate)
                        self.keys = .init(publicKey: generated[0], privateKey: generated[1])
                        print(wallet)
                    }
                }
            }
        }
        .padding()
    }
    
    private func refreshTallies() {
        guard let keys = keys else { return }
        refreshing = true
        let updateResult = getProposalTallys(contractAddress: contractAddress, publicKey: keys.publicKey, privateKey: keys.privateKey, walletKey: ethWalletPrivate)
        for (index, updatedTally) in updateResult.enumerated() {
            items[index].tally = Double(updatedTally) ?? 0
        }
        refreshing = false
    }
    
    private func refreshItems() {
        guard let keys = keys else { return }
        let result = getProposals(contractAddress: contractAddress, publicKey: keys.publicKey, privateKey: keys.privateKey, walletKey: ethWalletPrivate)
        items = result.map { Item(name: $0, tally: 0) }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
