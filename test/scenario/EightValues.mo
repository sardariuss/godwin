import Fuzz   "mo:fuzz";

import Buffer "mo:base/Buffer";
import Debug  "mo:base/Debug";

module {

  type Fuzzer = Fuzz.Fuzzer;

  type CategorizedQuestion = {
    text: Text;
    categorization: [(Text, Float)];
  };
  
  public class EightValues(){

    let _remainingQuestions = Buffer.fromArray<CategorizedQuestion>([
      {
        text = "Oppression by corporations is more of a concern than oppression by governments.";
        categorization = [
          ("ECONOMY"  , -1.0),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0.5 ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "It is necessary for the government to intervene in the economy to protect consumers.";
        categorization = [
          ("ECONOMY"  , -1.0),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "The freer the markets, the freer the people.";
        categorization = [
          ("ECONOMY"  , 1.0 ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "It is better to maintain a balanced budget than to ensure welfare for all citizens.";
        categorization = [
          ("ECONOMY"  , 1.0 ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "Publicly-funded research is more beneficial to the people than leaving it to the market.";
        categorization = [
          ("ECONOMY"  , -1.0),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , -1.0),
        ];
      },
      {
        text = "Tariffs on international trade are important to encourage local production.";
        categorization = [
          ("ECONOMY"  , -0.5),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 1.0 ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "From each according to his ability, to each according to his needs.";
        categorization = [
          ("ECONOMY"  , -1.0),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "It would be best if social programs were abolished in favor of private charity.";
        categorization = [
          ("ECONOMY"  , 1.0 ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "Taxes should be increased on the rich to provide for the poor.";
        categorization = [
          ("ECONOMY"  , -1.0),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "Inheritance is a legitimate form of wealth.";
        categorization = [
          ("ECONOMY"  , 1.0 ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , 0.5 ),
        ];
      },
      {
        text = "Basic utilities like roads and electricity should be publicly owned.";
        categorization = [
          ("ECONOMY"  , -1.0),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "Government intervention is a threat to the economy.";
        categorization = [
          ("ECONOMY"  , 1.0 ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "Those with a greater ability to pay should receive better healthcare.";
        categorization = [
          ("ECONOMY"  , 1.0 ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "Quality education is a right of all people.";
        categorization = [
          ("ECONOMY"  , -1.0),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , -0.5),
        ];
      },
      {
        text = "The means of production should belong to the workers who use them.";
        categorization = [
          ("ECONOMY"  , -1.0),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "The United Nations should be abolished.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 1.0 ),
          ("CIVIL"    , 0.5 ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "Military action by our nation is often necessary to protect it.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 1.0 ),
          ("CIVIL"    , 1.0 ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "I support regional unions, such as the European Union.";
        categorization = [
          ("ECONOMY"  , 0.5 ),
          ("DIPLOMATY", -1.0),
          ("CIVIL"    , -1.0),
          ("SOCIETY"  , -0.5),
        ];
      },
      {
        text = "It is important to maintain our national sovereignty.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 1.0 ),
          ("CIVIL"    , 0.5 ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "A united world government would be beneficial to mankind.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", -1.0),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "It is more important to retain peaceful relations than to further our strength.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", -1.0),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "Wars do not need to be justified to other countries.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 1.0 ),
          ("CIVIL"    , 1.0 ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "Military spending is a waste of money.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", -1.0),
          ("CIVIL"    , -1.0),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "International aid is a waste of money.";
        categorization = [
          ("ECONOMY"  , 0.5 ),
          ("DIPLOMATY", 1.0 ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "My nation is great.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 1.0 ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "Research should be conducted on an international scale.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", -1.0),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , -1.0),
        ];
      },
      {
        text = "Governments should be accountable to the international community.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", -1.0),
          ("CIVIL"    , -0.5),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "Even when protesting an authoritarian government, violence is not acceptable.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", -0.5),
          ("CIVIL"    , 0.5 ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "My religious values should be spread as much as possible.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0.5 ),
          ("CIVIL"    , 1.0 ),
          ("SOCIETY"  , 1.0 ),
        ];
      },
      {
        text = "Our nation's values should be spread as much as possible.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 1.0 ),
          ("CIVIL"    , 0.5 ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "It is very important to maintain law and order.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0.5 ),
          ("CIVIL"    , 1.0 ),
          ("SOCIETY"  , 0.5 ),
        ];
      },
      {
        text = "The general populace makes poor decisions.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 1.0 ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "Physician-assisted suicide should be legal.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , -1.0),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "The sacrifice of some civil liberties is necessary to protect us from acts of terrorism.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 1.0 ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "Government surveillance is necessary in the modern world.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 1.0 ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "The very existence of the state is a threat to our liberty.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , -1.0),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "Regardless of political opinions, it is important to side with your country.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 1.0 ),
          ("CIVIL"    , 1.0 ),
          ("SOCIETY"  , 0.5 ),
        ];
      },
      {
        text = "All authority should be questioned.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , -1.0),
          ("SOCIETY"  , -0.5),
        ];
      },
      {
        text = "A hierarchical state is best.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 1.0 ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "It is important that the government follows the majority opinion, even if it is wrong.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , -1.0),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "The stronger the leadership, the better.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 1.0 ),
          ("CIVIL"    , 1.0 ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "Democracy is more than a decision-making process.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , -1.0),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "Environmental regulations are essential.";
        categorization = [
          ("ECONOMY"  , -0.5),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , -1.0),
        ];
      },
      {
        text = "A better world will come from automation, science, and technology.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , -1.0),
        ];
      },
      {
        text = "Children should be educated in religious or traditional values.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0.5 ),
          ("SOCIETY"  , 1.0 ),
        ];
      },
      {
        text = "Traditions are of no value on their own.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , -1.0),
        ];
      },
      {
        text = "Religion should play a role in government.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 1.0 ),
          ("SOCIETY"  , 1.0 ),
        ];
      },
      {
        text = "Churches should be taxed the same way other institutions are taxed.";
        categorization = [
          ("ECONOMY"  , -0.5),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , -1.0),
        ];
      },
      {
        text = "Climate change is currently one of the greatest threats to our way of life.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , -1.0),
        ];
      },
      {
        text = "It is important that we work as a united world to combat climate change.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", -1.0),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , -1.0),
        ];
      },
      {
        text = "Society was better many years ago than it is now.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , 1.0 ),
        ];
      },
      {
        text = "It is important that we maintain the traditions of our past.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , 1.0 ),
        ];
      },
      {
        text = "It is important that we think in the long term, beyond our lifespans.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , -1.0),
        ];
      },
      {
        text = "Reason is more important than maintaining our culture.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , -1.0),
        ];
      },
      {
        text = "Drug use should be legalized or decriminalized.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , -1.0),
          ("SOCIETY"  , -0.5),
        ];
      },
      {
        text = "Same-sex marriage should be legal.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , -1.0),
          ("SOCIETY"  , -1.0),
        ];
      },
      {
        text = "No cultures are superior to others.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", -1.0),
          ("CIVIL"    , -0.5),
          ("SOCIETY"  , -1.0),
        ];
      },
      {
        text = "Sex outside marriage is immoral.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0.5 ),
          ("SOCIETY"  , 1.0 ),
        ];
      },
      {
        text = "If we accept migrants at all, it is important that they assimilate into our culture.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0.5 ),
          ("SOCIETY"  , 1.0 ),
        ];
      },
      {
        text = "Abortion should be prohibited in most or all cases.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 1.0 ),
          ("SOCIETY"  , 1.0 ),
        ];
      },
      {
        text = "Gun ownership should be prohibited for those without a valid reason.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 1.0 ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "I support single-payer, universal healthcare.";
        categorization = [
          ("ECONOMY"  , -1.0),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "Prostitution should be illegal.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 1.0 ),
          ("SOCIETY"  , 1.0 ),
        ];
      },
      {
        text = "Maintaining family values is essential.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , 1.0 ),
        ];
      },
      {
        text = "To chase progress at all costs is dangerous.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , 1.0 ),
        ];
      },
      {
        text = "Genetic modification is a force for good, even on humans.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", 0   ),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , -1.0),
        ];
      },
      {
        text = "We should open our borders to immigration.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", -1.0),
          ("CIVIL"    , -1.0),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "Governments should be as concerned about foreigners as they are about their own citizens.";
        categorization = [
          ("ECONOMY"  , 0   ),
          ("DIPLOMATY", -1.0),
          ("CIVIL"    , 0   ),
          ("SOCIETY"  , 0   ),
        ];
      },
      {
        text = "All people - regardless of factors like culture or sexuality - should be treated equally.";
        categorization = [
          ("ECONOMY"  , -1.0),
          ("DIPLOMATY", -1.0),
          ("CIVIL"    , -1.0),
          ("SOCIETY"  , -1.0),
        ];
      },
      {
        text = "It is important that we further my group's goals above all others.";
        categorization = [
          ("ECONOMY"  , 1.0 ),
          ("DIPLOMATY", 1.0 ),
          ("CIVIL"    , 1.0 ),
          ("SOCIETY"  , 1.0 ),
        ];
      }
    ]);

    public func pickQuestion(fuzzer: Fuzzer): CategorizedQuestion {
      if (_remainingQuestions.size() == 0) {
        Debug.trap("There is no more questions in the buffer");
      };
      let index = fuzzer.nat.randomRange(0, _remainingQuestions.size() - 1);
      let question = _remainingQuestions.get(index);
      ignore _remainingQuestions.remove(index);
      return question;
    };

  };
};