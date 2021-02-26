# frozen_string_literal: true

module Decidim
  module Proposals
    # Exposes the proposal vote resource so users can vote proposals.
    class ProposalVotesController < Decidim::Proposals::ApplicationController
      include ProposalVotesHelper
      include Rectify::ControllerHelpers

      helper_method :proposal

      before_action :authenticate_user!

      def create
        enforce_permission_to :vote, :proposal, proposal: proposal
        @from_proposals_list = params[:from_proposals_list] == "true"

        VoteProposal.call(proposal, current_user) do
          on(:ok) do
            proposal.reload

            # TODO: Replace with search that uses LV proposals to select which proposals to include.
            proposals = ProposalVote.where(
              author: current_user,
              proposal: Proposal.where(component: current_component)
            ).map(&:proposal)

            expose(proposals: proposals + [proposal], lv_state: lv_state)
            render :update_buttons_and_counters
          end

          on(:invalid) do
            render json: {
              error: I18n.t("proposal_votes.create.error", scope: "decidim.proposals")
            }, status: :unprocessable_entity
          end
        end
      end

      def destroy
        enforce_permission_to :unvote, :proposal, proposal: proposal
        @from_proposals_list = params[:from_proposals_list] == "true"

        UnvoteProposal.call(proposal, current_user) do
          on(:ok) do
            proposal.reload

            # TODO: Replace with search that uses LV proposals to select which proposals to include.
            proposals = ProposalVote.where(
              author: current_user,
              proposal: Proposal.where(component: current_component)
            ).map(&:proposal)

            expose(proposals: proposals + [proposal], lv_state: lv_state)
            render :update_buttons_and_counters
          end
        end
      end

      private

      def proposal
        @proposal ||= Proposal.where(component: current_component).find(params[:proposal_id])
      end

      def lv_state
        # don't conditionally assign, always get a fresh one
        @lv_state = Decidim::Liquidvoting::Client.current_proposal_state(
          current_user&.email,
          ResourceLocatorPresenter.new(proposal).url
        )
      end
    end
  end
end