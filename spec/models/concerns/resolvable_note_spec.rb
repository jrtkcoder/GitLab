require 'spec_helper'

describe Note, ResolvableNote, models: true do
  subject { create(:discussion_note_on_merge_request) }

  describe '.resolvable' do
    # TODO: Test
  end

  describe '.resolved' do
    # TODO: Test
  end

  describe '.unresolved' do
    # TODO: Test
  end

  describe ".resolve!" do
    let(:current_user) { create(:user) }
    let!(:commit_note) { create(:diff_note_on_commit) }
    let!(:resolved_note) { create(:discussion_note_on_merge_request, :resolved) }
    let!(:unresolved_note) { create(:discussion_note_on_merge_request) }

    before do
      described_class.resolve!(current_user)

      commit_note.reload
      resolved_note.reload
      unresolved_note.reload
    end

    it 'resolves only the resolvable, not yet resolved notes' do
      expect(commit_note.resolved_at).to be_nil
      expect(resolved_note.resolved_by).not_to eq(current_user)
      expect(unresolved_note.resolved_at).not_to be_nil
      expect(unresolved_note.resolved_by).to eq(current_user)
    end
  end

  describe ".unresolve!" do
    let!(:resolved_note) { create(:discussion_note_on_merge_request, :resolved) }

    before do
      described_class.unresolve!

      resolved_note.reload
    end

    it 'unresolves the resolved notes' do
      expect(resolved_note.resolved_by).to be_nil
      expect(resolved_note.resolved_at).to be_nil
    end
  end

  describe '#discussion_resolvable?' do
    # TODO: Test
  end

  describe '#resolvable?' do
    context "when potentially resolvable" do
      before do
        allow(subject).to receive(:discussion_resolvable?).and_return(true)
      end

      context "when a system note" do
        before do
          subject.system = true
        end

        it "returns false" do
          expect(subject.resolvable?).to be false
        end
      end

      context "when a regular note" do
        it "returns true" do
          expect(subject.resolvable?).to be true
        end
      end
    end

    context "when not potentially resolvable" do
      before do
        allow(subject).to receive(:discussion_resolvable?).and_return(false)
      end

      it "returns false" do
        expect(subject.resolvable?).to be false
      end
    end
  end

  describe "#to_be_resolved?" do
    context "when not resolvable" do
      before do
        allow(subject).to receive(:resolvable?).and_return(false)
      end

      it "returns false" do
        expect(subject.to_be_resolved?).to be false
      end
    end

    context "when resolvable" do
      before do
        allow(subject).to receive(:resolvable?).and_return(true)
      end

      context "when resolved" do
        before do
          allow(subject).to receive(:resolved?).and_return(true)
        end

        it "returns false" do
          expect(subject.to_be_resolved?).to be false
        end
      end

      context "when not resolved" do
        before do
          allow(subject).to receive(:resolved?).and_return(false)
        end

        it "returns true" do
          expect(subject.to_be_resolved?).to be true
        end
      end
    end
  end

  describe "#resolve!" do
    let(:current_user) { create(:user) }

    context "when not resolvable" do
      before do
        allow(subject).to receive(:resolvable?).and_return(false)
      end

      it "returns nil" do
        expect(subject.resolve!(current_user)).to be_nil
      end

      it "doesn't set resolved_at" do
        subject.resolve!(current_user)

        expect(subject.resolved_at).to be_nil
      end

      it "doesn't set resolved_by" do
        subject.resolve!(current_user)

        expect(subject.resolved_by).to be_nil
      end

      it "doesn't mark as resolved" do
        subject.resolve!(current_user)

        expect(subject.resolved?).to be false
      end
    end

    context "when resolvable" do
      before do
        allow(subject).to receive(:resolvable?).and_return(true)
      end

      context "when already resolved" do
        let(:user) { create(:user) }

        before do
          subject.resolve!(user)
        end

        it "returns nil" do
          expect(subject.resolve!(current_user)).to be_nil
        end

        it "doesn't change resolved_at" do
          expect(subject.resolved_at).not_to be_nil

          expect { subject.resolve!(current_user) }.not_to change { subject.resolved_at }
        end

        it "doesn't change resolved_by" do
          expect(subject.resolved_by).to eq(user)

          expect { subject.resolve!(current_user) }.not_to change { subject.resolved_by }
        end

        it "doesn't change resolved status" do
          expect(subject.resolved?).to be true

          expect { subject.resolve!(current_user) }.not_to change { subject.resolved? }
        end
      end

      context "when not yet resolved" do
        it "returns true" do
          expect(subject.resolve!(current_user)).to be true
        end

        it "sets resolved_at" do
          subject.resolve!(current_user)

          expect(subject.resolved_at).not_to be_nil
        end

        it "sets resolved_by" do
          subject.resolve!(current_user)

          expect(subject.resolved_by).to eq(current_user)
        end

        it "marks as resolved" do
          subject.resolve!(current_user)

          expect(subject.resolved?).to be true
        end
      end
    end
  end

  describe "#unresolve!" do
    context "when not resolvable" do
      before do
        allow(subject).to receive(:resolvable?).and_return(false)
      end

      it "returns nil" do
        expect(subject.unresolve!).to be_nil
      end
    end

    context "when resolvable" do
      before do
        allow(subject).to receive(:resolvable?).and_return(true)
      end

      context "when resolved" do
        let(:user) { create(:user) }

        before do
          subject.resolve!(user)
        end

        it "returns true" do
          expect(subject.unresolve!).to be true
        end

        it "unsets resolved_at" do
          subject.unresolve!

          expect(subject.resolved_at).to be_nil
        end

        it "unsets resolved_by" do
          subject.unresolve!

          expect(subject.resolved_by).to be_nil
        end

        it "unmarks as resolved" do
          subject.unresolve!

          expect(subject.resolved?).to be false
        end
      end

      context "when not resolved" do
        it "returns nil" do
          expect(subject.unresolve!).to be_nil
        end
      end
    end
  end
end
