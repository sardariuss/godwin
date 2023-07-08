import VoteTypes              "votes/Types";
import QuestionTypes          "questions/Types";
import PayRules               "PayRules";
import Model                  "Model";
import Categories             "Categories";
import Facade                 "Facade";
import StatusManager          "questions/StatusManager";
import Questions              "questions/Questions";
import QuestionQueriesFactory "questions/QueriesFactory";
import Controller             "controller/Controller";
import Votes                  "votes/Votes";
import QuestionVoteJoins      "votes/QuestionVoteJoins";
import Interests              "votes/Interests";
import Categorizations        "votes/Categorizations";
import Opinions               "votes/Opinions";
import VotersHistory          "votes/VotersHistory";
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

    let pay_rules = PayRules.build(state.price_params);

    let token_interface = TokenInterface.build(state.master.v);
    let pay_to_open_question = PayForNew.build(
      token_interface,
      #OPEN_QUESTION,
      state.opened_questions.register,
      state.opened_questions.index,
      state.opened_questions.transactions
    );

    let interest_joins = QuestionVoteJoins.build(state.votes.interest.joins);

    let interest_voters_history = VotersHistory.VotersHistory(state.votes.interest.voters_history, interest_joins);
    
    let interests = Interests.build(
      state.votes.interest.register,
      interest_voters_history,
      state.votes.interest.transactions,
      token_interface,
      pay_to_open_question,
      interest_joins,
      queries,
      pay_rules,
      state.decay_params.v
    );
    
    let opinion_joins = QuestionVoteJoins.build(state.votes.opinion.joins);

    let opinion_voters_history = VotersHistory.VotersHistory(state.votes.opinion.voters_history, opinion_joins);
    
    let opinions = Opinions.build(
      state.votes.opinion.register,
      opinion_voters_history,
      state.decay_params.v
    );
    
    let categorization_joins = QuestionVoteJoins.build(state.votes.categorization.joins);

    let categorization_voters_history = VotersHistory.VotersHistory(state.votes.categorization.voters_history, categorization_joins);
    
    let categorizations = Categorizations.build(
      state.votes.categorization.register,
      categorization_voters_history,
      state.votes.categorization.transactions,
      token_interface,
      categories,
      pay_rules,
      state.decay_params.v
    );

    let status_manager = StatusManager.build(
      state.status.register,
      interest_joins,
      opinion_joins,
      categorization_joins
    );

    let model = Model.Model(
      WRef.WRef(state.name),
      WRef.WRef(state.master),
      WRef.WRef(state.momentum_args),
      WRef.WRef(state.scheduler_params),
      WRef.WRef(state.decay_params),
      categories,
      questions,
      status_manager,
      queries,
      interests,
      opinions,
      categorizations,
      interest_voters_history,
      opinion_voters_history,
      categorization_voters_history,
      interest_joins,
      opinion_joins,
      categorization_joins,
    );

    let controller = Controller.build(model);

    let facade = Facade.Facade(controller);

    facade;
  };

};