class SoulsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "souls_dashboard"
    stream_from "incarnations"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end