require 'spec_helper'

RSpec.describe 'PPE Canary' do
  it 'confirms artifact poisoning chain' do
    coverage_dir = './coverage'
    Dir.mkdir(coverage_dir) unless Dir.exist?(coverage_dir)
    
    marker = <<~MARKER
      =========================================
      PPE CANARY — Attack Chain Confirmed
      Timestamp: #{Time.now.utc}
      Runner: #{ENV['RUNNER_OS'] || 'unknown'}
      Workflow: Test (fork context)
      =========================================
      If you see this file in the Coverage workflow,
      the artifact poisoning chain is FUNCTIONAL.
    MARKER
    
    File.write("#{coverage_dir}/CANARY_PPE_CONFIRMED.txt", marker)
    expect(true).to be true
  end
end
