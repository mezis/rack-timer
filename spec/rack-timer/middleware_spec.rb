require 'spec_helper'
require 'rack-timer'

describe RackTimer::Middleware do
  let(:buffer) { StringIO.new }
  let(:output) { buffer.rewind ; buffer.read }
  let(:app) { build_stack *stack }
  let(:stack) { [Test::App, Test::FastMiddleware, RackTimer::Middleware] }

  before do
    RackTimer.output = buffer
  end

  def build_stack(app_class, *middlewares)
    app = app_class.new
    middlewares.each do |m|
      app = m.new(app)
    end
    app
  end

  describe 'assimilation' do
    it 'gets logged' do
      app
      output.should =~ /assimilating: RackTimer::Middleware/
      output.should =~ /assimilating: Test::FastMiddleware/
    end
  end

  describe 'middleware timing' do
    it 'logs app timing' do
      app.call({})
      output.should =~ /Test::App took \d+ us/
    end

    it 'logs middleware timing' do
      app.call({})
      output.should =~ /Test::FastMiddleware took \d+ us/
    end

    context 'with a slow middleware' do
      let(:stack) { [Test::App, Test::SlowMiddleware, Test::FastMiddleware, RackTimer::Middleware] }
      
      it 'times the slow middleware' do
        app.call({})
        output.should =~ /Test::SlowMiddleware took \d+ us/
      end

      it 'does not include the slow middleware time in the outer middleware' do
        app.call({})
        time_slow = /Test::SlowMiddleware took (?<time>\d+) us/.match(output)[:time].to_i
        time_fast = /Test::FastMiddleware took (?<time>\d+) us/.match(output)[:time].to_i
        time_slow.should > 250_000
        time_fast.should < time_slow
      end
    end
  end

  describe 'queue timing' do
    let(:timestamp) { (Time.now.to_f * 1e6).to_i }
    let(:env) {{ 'HTTP_X_REQUEST_START' => "t=#{timestamp}" }}

    it 'adds queue time when HTTP_X_REQUEST_START present' do
      app.call(env)
      output.should =~ /queued for \d+ us/
    end

  end
end
