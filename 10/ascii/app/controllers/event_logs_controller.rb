module Controllers
  class EventLogsController
    def self.render(args, sprites, labels)
      labels << events_as_labels(args.state.event_logs[0..20])
    end

    def self.reset(state)
      state.event_logs = []
    end

    def self.log_event(event)
      $gtk.args.state.event_logs.unshift(event)
    end

    LOG_TOP = 650
    def self.events_as_labels(events)
      events.map.with_index do |event, index|
        alpha = 255 - (index * 15)
        [16, LOG_TOP - (index * 40), event, 230, 230, 230, alpha]
      end
    end
  end
end
