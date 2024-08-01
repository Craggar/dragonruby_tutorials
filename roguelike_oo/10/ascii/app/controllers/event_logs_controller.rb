module Controllers
  class EventLogsController
    LOG_TOP = 650

    def self.events_as_labels(args)
      args.state.event_logs.map.with_index do |event, index|
        alpha = 255 - (index * 15)
        {x: 16, y: LOG_TOP - (index * 40), text: event, r: 230, g: 230, b: 230, a: alpha}
      end
    end

    def self.log_event(event)
      $gtk.args.state.event_logs.unshift(event)
      $gtk.args.state.logged_event_this_tick = true
    end

    def self.reset(state)
      state.event_logs = []
      state.logged_event_this_tick = false
    end
  end
end
