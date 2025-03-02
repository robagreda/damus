//
//  EventHolder.swift
//  damus
//
//  Created by William Casarin on 2023-02-19.
//

import Foundation

/// Used for holding back events until they're ready to be displayed
class EventHolder: ObservableObject, ScrollQueue {
    private var has_event: Set<String>
    @Published var events: [NostrEvent]
    @Published var incoming: [NostrEvent]
    var should_queue: Bool
    var on_queue: ((NostrEvent) -> Void)?
    
    func set_should_queue(_ val: Bool) {
        self.should_queue = val
    }
    
    var queued: Int {
        return incoming.count
    }
    
    var all_events: [NostrEvent] {
        events + incoming
    }
    
    init() {
        self.should_queue = false
        self.events = []
        self.incoming = []
        self.has_event = Set()
        self.on_queue = nil
    }
    
    init(on_queue: @escaping (NostrEvent) -> ()) {
        self.should_queue = false
        self.events = []
        self.incoming = []
        self.has_event = Set()
        self.on_queue = on_queue
    }
    
    init(events: [NostrEvent], incoming: [NostrEvent]) {
        self.should_queue = false
        self.events = events
        self.incoming = incoming
        self.has_event = Set()
        self.on_queue = nil
    }
    
    func filter(_ isIncluded: (NostrEvent) -> Bool) {
        self.events = self.events.filter(isIncluded)
        self.incoming = self.incoming.filter(isIncluded)
    }
    
    func insert(_ ev: NostrEvent) -> Bool {
        if should_queue {
            return insert_queued(ev)
        } else {
            return insert_immediate(ev)
        }
    }
    
    private func insert_immediate(_ ev: NostrEvent) -> Bool {
        if has_event.contains(ev.id) {
            return false
        }
        
        has_event.insert(ev.id)
        
        if insert_uniq_sorted_event_created(events: &self.events, new_ev: ev) {
            return true
        }
        
        return false
    }
    
    private func insert_queued(_ ev: NostrEvent) -> Bool {
        if has_event.contains(ev.id) {
            return false
        }
        
        on_queue?(ev)
        
        has_event.insert(ev.id)
        
        incoming.append(ev)
        return true
    }
    
    func flush() {
        guard !incoming.isEmpty else {
            return
        }
        
        var changed = false
        for event in incoming {
            if insert_uniq_sorted_event_created(events: &events, new_ev: event) {
                changed = true
            }
        }
        
        if changed {
            self.objectWillChange.send()
        }
        
        self.incoming = []
    }
}
