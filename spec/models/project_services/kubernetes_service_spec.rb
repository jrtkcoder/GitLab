require 'spec_helper'

describe KubernetesService, models: true do
  let(:project) { create(:empty_project) }

  describe "Associations" do
    it { is_expected.to belong_to :project }
  end

  describe 'Validations' do
    context 'when service is active' do
      before { subject.active = true }
      it { is_expected.to validate_presence_of(:namespace) }
      it { is_expected.to validate_presence_of(:api_url) }
      it { is_expected.to validate_presence_of(:token) }

      context 'namespace format' do
        before do
          subject.project = project
          subject.api_url = "http://example.com"
          subject.token = "test"
        end

        {
          'foo'  => true,
          '1foo' => true,
          'foo1' => true,
          'foo-bar' => true,
          '-foo' => false,
          'foo-' => false,
          'a' * 63 => true,
          'a' * 64 => false,
          'a.b' => false,
          'a*b' => false,
        }.each do |namespace, validity|
          it "should validate #{namespace} as #{validity ? 'valid' : 'invalid'}" do
            subject.namespace = namespace

            expect(subject.valid?).to eq(validity)
          end
        end
      end
    end

    context 'when service is inactive' do
      before { subject.active = false }
      it { is_expected.not_to validate_presence_of(:namespace) }
      it { is_expected.not_to validate_presence_of(:api_url) }
      it { is_expected.not_to validate_presence_of(:token) }
    end
  end

  describe '#initialize_properties' do
    context 'with a project' do
      it 'defaults to the project name' do
        expect(described_class.new(project: project).namespace).to eq(project.name)
      end
    end

    context 'without a project' do
      it 'leaves the namespace unset' do
        expect(described_class.new.namespace).to be_nil
      end
    end
  end

  describe '#test' do
    let(:project) { create(:kubernetes_project) }
    let(:service) { project.kubernetes_service }
    let(:discovery_url) { service.api_url + '/api/v1' }

    # JSON response body from Kubernetes GET /api/v1 request
    let(:discovery_response) { { "kind" => "APIResourceList", "groupVersion" => "v1", "resources" => [] }.to_json }

    context 'with path prefix in api_url' do
      let(:discovery_url) { 'https://kubernetes.example.com/prefix/api/v1' }

      before do
        service.api_url = 'https://kubernetes.example.com/prefix/'
      end

      it 'tests with the prefix' do
        WebMock.stub_request(:get, discovery_url).to_return(body: discovery_response)

        expect(service.test[:success]).to be_truthy
        expect(WebMock).to have_requested(:get, discovery_url).once
      end
    end

    context 'with custom CA certificate' do
      let(:certificate) { "CA PEM DATA" }
      before do
        service.update_attributes!(ca_pem: certificate)
      end

      it 'is added to the certificate store' do
        cert = double("certificate")

        expect(OpenSSL::X509::Certificate).to receive(:new).with(certificate).and_return(cert)
        expect_any_instance_of(OpenSSL::X509::Store).to receive(:add_cert).with(cert)
        WebMock.stub_request(:get, discovery_url).to_return(body: discovery_response)

        expect(service.test[:success]).to be_truthy
        expect(WebMock).to have_requested(:get, discovery_url).once
      end
    end

    context 'success' do
      it 'reads the discovery endpoint' do
        WebMock.stub_request(:get, discovery_url).to_return(body: discovery_response)

        expect(service.test[:success]).to be_truthy
        expect(WebMock).to have_requested(:get, discovery_url).once
      end
    end

    context 'failure' do
      it 'fails to read the discovery endpoint' do
        WebMock.stub_request(:get, discovery_url).to_return(status: 404)

        expect(service.test[:success]).to be_falsy
        expect(WebMock).to have_requested(:get, discovery_url).once
      end
    end
  end
end
