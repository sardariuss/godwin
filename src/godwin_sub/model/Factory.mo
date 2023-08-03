import QuestionTypes          "questions/Types";
import PayRules               "PayRules";
import Model                  "Model";
import Categories             "Categories";
import Facade                 "Facade";
import StatusManager          "StatusManager";
import SubMomentum            "SubMomentum";
import Questions              "questions/Questions";
import QuestionQueriesFactory "questions/QueriesFactory";
import Controller             "controller/Controller";
import VoteTypes              "votes/Types";
import Votes                  "votes/Votes";
import VotersHistory          "votes/VotersHistory";
import QuestionVoteJoins      "votes/QuestionVoteJoins";
import Interests              "votes/Interests";
import Categorizations        "votes/Categorizations";
import Opinions               "votes/Opinions";
import Polarization           "votes/representation/Polarization";
import PolarizationMap        "votes/representation/PolarizationMap";
import SubaccountGenerator    "token/SubaccountGenerator";
import TokenInterface         "token/TokenInterface";
import PayForNew              "token/PayForNew";
import StableTypes            "../stable/Types";

import WRef                   "../utils/wrappers/WRef";

module {

  type Question        = QuestionTypes.Question;
  type Status          = QuestionTypes.Status;
  type Cursor          = VoteTypes.Cursor;
  type Polarization    = VoteTypes.Polarization;
  type CursorMap       = VoteTypes.CursorMap;
  type PolarizationMap = VoteTypes.PolarizationMap;
  type Facade          = Facade.Facade;
  type State           = StableTypes.Current.State;

  public func build(state: State) : Facade {

    let master = state.master;
    
    let categories = Categories.build(state.categories);
    
    let questions = Questions.Questions(state.questions);

    let queries = QuestionQueriesFactory.build(state.queries.register);

    let sub_momentum = SubMomentum.build(state.momentum, state.selection_params);

    let pay_rules = PayRules.build(state.price_register);

    let token_interface = TokenInterface.build(state.master.v);
    let pay_to_open_question = PayForNew.build(
      token_interface,
      #OPEN_QUESTION,
      state.opened_questions.register,
      state.opened_questions.index,
      state.opened_questions.transactions
    );

    let interest_join = QuestionVoteJoins.build(state.votes.interest.joins);
    let interest_voters_history = VotersHistory.VotersHistory(state.votes.interest.voters_history, interest_join);
    
    let interests = Interests.build(
      state.votes.interest.register,
      interest_voters_history,
      state.votes.interest.transactions,
      token_interface,
      pay_to_open_question,
      interest_join,
      queries,
      pay_rules,
      state.creator,
      state.opened_questions.creator_rewards);
    
    let opinion_join = QuestionVoteJoins.build(state.votes.opinion.joins);
    let opinion_voters_history = VotersHistory.VotersHistory(state.votes.opinion.voters_history, opinion_join);
    
    let opinions = Opinions.build(
      state.votes.opinion.register,
      opinion_voters_history,
      WRef.WRef(state.votes.opinion.vote_decay_params),
      WRef.WRef(state.votes.opinion.late_ballot_decay_params));
    
    let categorization_join = QuestionVoteJoins.build(state.votes.categorization.joins);
    let categorization_voters_history = VotersHistory.VotersHistory(state.votes.categorization.voters_history, categorization_join);
    
    let categorizations = Categorizations.build(
      state.votes.categorization.register,
      categorization_voters_history,
      state.votes.categorization.transactions,
      token_interface,
      categories,
      pay_rules
    );

    let status_manager = StatusManager.build(
      state.status.register,
      interest_join,
      opinion_join,
      categorization_join
    );

    let model = Model.Model(
      WRef.WRef(state.name),
      WRef.WRef(state.master),
      WRef.WRef(state.scheduler_params),
      WRef.WRef(state.selection_params),
      WRef.WRef(state.base_price_params),
      categories,
      pay_rules,
      questions,
      status_manager,
      sub_momentum,
      queries,
      interests,
      opinions,
      categorizations,
      interest_join,
      opinion_join,
      categorization_join,
      interest_voters_history,
      opinion_voters_history,
      categorization_voters_history
    );

    let controller = Controller.build(model);

    let facade = Facade.Facade(controller);

    facade;
  };

};