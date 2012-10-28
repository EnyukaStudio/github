# encoding: utf-8

require 'spec_helper'

describe Github::Repos::Downloads, '#list' do
  let(:user) { 'peter-murach' }
  let(:repo) { 'github' }
  let(:request_path) { "/repos/#{user}/#{repo}/downloads" }

  before {
    stub_get(request_path).
      to_return(:body => body, :status => status,
        :headers => {:content_type => "application/json; charset=utf-8"})
  }

  after { reset_authentication_for(subject) }

  context "resource found" do
    let(:body)   { fixture('repos/downloads.json') }
    let(:status) { 200 }

    it { should respond_to :all }

    it "should fail to get resource without username" do
      expect { subject.list }.to raise_error(ArgumentError)
    end

    it "should get the resources" do
      subject.list user, repo
      a_get(request_path).should have_been_made
    end

    it "should return array of resources" do
      downloads = subject.list user, repo
      downloads.should be_an Array
      downloads.should have(1).items
    end

    it "should be a mash type" do
      downloads = subject.list user, repo
      downloads.first.should be_a Hashie::Mash
    end

    it "should get download information" do
      downloads = subject.list user, repo
      downloads.first.name.should == 'new_file.jpg'
    end

    it "should yield to a block" do
      subject.should_receive(:list).with(user, repo).and_yield('web')
      subject.list(user, repo) { |param| 'web' }
    end
  end

  context "resource not found" do
    let(:body)   { "" }
    let(:status) { [404, "Not Found"] }

    it "should return 404 with a message 'Not Found'" do
      expect { subject.list user, repo }.to raise_error(Github::Error::NotFound)
    end
  end
end # list