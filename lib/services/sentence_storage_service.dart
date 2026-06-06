import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pronunciation_engine/pronunciation_engine.dart';

class SentenceStorageService {
  static const String _storageKey = 'practice_sentences_db';

  // Default initial practice sentences
  static final List<PracticeSentence> _defaultSentences = [
    PracticeSentence(
      id: 'gdd_1',
      text: "I'm so excited.",
      category: "Stage 1",
      chunks: ["I'm", "so excited"],
      translation: "정말 신나요.",
    ),
    PracticeSentence(
      id: 'gdd_2',
      text: "I'm not tired.",
      category: "Stage 1",
      chunks: ["I'm", "not tired"],
      translation: "피곤하지 않아요.",
    ),
    PracticeSentence(
      id: 'gdd_3',
      text: "You are so kind.",
      category: "Stage 1",
      chunks: ["You are", "so kind"],
      translation: "당신은 정말 친절해요.",
    ),
    PracticeSentence(
      id: 'gdd_4',
      text: "He is a student.",
      category: "Stage 1",
      chunks: ["He is", "a student"],
      translation: "그는 학생입니다.",
    ),
    PracticeSentence(
      id: 'gdd_5',
      text: "She is kind.",
      category: "Stage 1",
      chunks: ["She is", "kind"],
      translation: "그녀는 친절해요.",
    ),
    PracticeSentence(
      id: 'gdd_6',
      text: "It's easy.",
      category: "Stage 1",
      chunks: ["It's", "easy"],
      translation: "쉬워요.",
    ),
    PracticeSentence(
      id: 'gdd_7',
      text: "It's not easy.",
      category: "Stage 1",
      chunks: ["It's", "not easy"],
      translation: "쉽지 않아요.",
    ),
    PracticeSentence(
      id: 'gdd_8',
      text: "I like dancing.",
      category: "Stage 1",
      chunks: ["I like", "dancing"],
      translation: "저는 춤추는 것을 좋아해요.",
    ),
    PracticeSentence(
      id: 'gdd_9',
      text: "I don't like working out.",
      category: "Stage 1",
      chunks: ["I don't like", "working out"],
      translation: "저는 운동하는 것을 좋아하지 않아요.",
    ),
    PracticeSentence(
      id: 'gdd_10',
      text: "Do you like coffee?",
      category: "Stage 1",
      chunks: ["Do you like", "coffee"],
      translation: "커피 좋아하세요?",
    ),
    PracticeSentence(
      id: 'gdd_11',
      text: "I don't know him.",
      category: "Stage 1",
      chunks: ["I don't know", "him"],
      translation: "저는 그를 모릅니다.",
    ),
    PracticeSentence(
      id: 'gdd_12',
      text: "What do you do?",
      category: "Stage 1",
      chunks: ["What", "do you do"],
      translation: "무슨 일을 하세요?",
    ),
    PracticeSentence(
      id: 'gdd_13',
      text: "Where do you live?",
      category: "Stage 1",
      chunks: ["Where", "do you live"],
      translation: "어디에 사세요?",
    ),
    PracticeSentence(
      id: 'gdd_14',
      text: "Are you busy now?",
      category: "Stage 1",
      chunks: ["Are you", "busy now"],
      translation: "지금 바쁘신가요?",
    ),
    PracticeSentence(
      id: 'gdd_15',
      text: "Were you busy last weekend?",
      category: "Stage 2",
      chunks: ["Were you busy", "last weekend"],
      translation: "지난 주말에 바빴어요?",
    ),
    PracticeSentence(
      id: 'gdd_16',
      text: "I'm driving now.",
      category: "Stage 2",
      chunks: ["I'm driving", "now"],
      translation: "지금 운전 중이에요.",
    ),
    PracticeSentence(
      id: 'gdd_17',
      text: "I'm looking for my glasses.",
      category: "Stage 2",
      chunks: ["I'm looking for", "my glasses"],
      translation: "안경을 찾고 있어요.",
    ),
    PracticeSentence(
      id: 'gdd_18',
      text: "I never skip breakfast.",
      category: "Stage 2",
      chunks: ["I never skip", "breakfast"],
      translation: "저는 아침을 절대 거르지 않아요.",
    ),
    PracticeSentence(
      id: 'gdd_19',
      text: "I always try my best.",
      category: "Stage 2",
      chunks: ["I always", "try my best"],
      translation: "저는 항상 최선을 다합니다.",
    ),
    PracticeSentence(
      id: 'gdd_20',
      text: "I usually meet friends on weekends.",
      category: "Stage 2",
      chunks: ["I usually meet friends", "on weekends"],
      translation: "저는 보통 주말에 친구들을 만납니다.",
    ),
    PracticeSentence(
      id: 'gdd_21',
      text: "I sometimes travel alone.",
      category: "Stage 2",
      chunks: ["I sometimes", "travel alone"],
      translation: "저는 가끔 혼자 여행해요.",
    ),
    PracticeSentence(
      id: 'gdd_22',
      text: "I'm looking forward to the weekend.",
      category: "Stage 2",
      chunks: ["I'm looking forward to", "the weekend"],
      translation: "주말이 정말 기다려집니다.",
    ),
    PracticeSentence(
      id: 'gdd_23',
      text: "There is a cafe nearby.",
      category: "Stage 3",
      chunks: ["There is a cafe", "nearby"],
      translation: "근처에 카페가 있어요.",
    ),
    PracticeSentence(
      id: 'gdd_24',
      text: "I have a car.",
      category: "Stage 3",
      chunks: ["I have", "a car"],
      translation: "저는 차가 있습니다.",
    ),
    PracticeSentence(
      id: 'gdd_25',
      text: "I don't have a car.",
      category: "Stage 3",
      chunks: ["I don't have", "a car"],
      translation: "저는 차가 없어요.",
    ),
    PracticeSentence(
      id: 'gdd_26',
      text: "Do you have decaf coffee?",
      category: "Stage 3",
      chunks: ["Do you have", "decaf coffee"],
      translation: "디카페인 커피 있나요?",
    ),
    PracticeSentence(
      id: 'gdd_27',
      text: "I feel a bit cold.",
      category: "Stage 3",
      chunks: ["I feel", "a bit cold"],
      translation: "약간 춥게 느껴져요.",
    ),
    PracticeSentence(
      id: 'gdd_28',
      text: "I'm good at finding ways.",
      category: "Stage 3",
      chunks: ["I'm good at", "finding ways"],
      translation: "저는 길을 잘 찾아요.",
    ),
    PracticeSentence(
      id: 'gdd_29',
      text: "I'm not good at driving.",
      category: "Stage 3",
      chunks: ["I'm not good at", "driving"],
      translation: "저는 운전을 잘 못해요.",
    ),
    PracticeSentence(
      id: 'gdd_30',
      text: "Originally, this is the entrance.",
      category: "Stage 3",
      chunks: ["Originally", "this is the entrance"],
      translation: "원래 여기가 입구입니다.",
    ),
    PracticeSentence(
      id: 'gdd_31',
      text: "Let's take a picture together.",
      category: "Stage 4",
      chunks: ["Let's take", "a picture together"],
      translation: "함께 사진 찍어요.",
    ),
    PracticeSentence(
      id: 'gdd_32',
      text: "I want to travel.",
      category: "Stage 4",
      chunks: ["I want", "to travel"],
      translation: "여행 가고 싶어요.",
    ),
    PracticeSentence(
      id: 'gdd_33',
      text: "I have to go to bed early.",
      category: "Stage 4",
      chunks: ["I have to", "go to bed early"],
      translation: "일찍 자야 해요.",
    ),
    PracticeSentence(
      id: 'gdd_34',
      text: "I'll call you.",
      category: "Stage 4",
      chunks: ["I'll", "call you"],
      translation: "전화할게요.",
    ),
    PracticeSentence(
      id: 'gdd_35',
      text: "I can ride a bike.",
      category: "Stage 4",
      chunks: ["I can ride", "a bike"],
      translation: "자전거 탈 줄 알아요.",
    ),
    PracticeSentence(
      id: 'gdd_36',
      text: "I can't play the piano.",
      category: "Stage 4",
      chunks: ["I can't play", "the piano"],
      translation: "피아노 칠 줄 몰라요.",
    ),
    PracticeSentence(
      id: 'gdd_37',
      text: "You should see a doctor.",
      category: "Stage 4",
      chunks: ["You should", "see a doctor"],
      translation: "병원에 가보시는 게 좋겠어요.",
    ),
    PracticeSentence(
      id: 'gdd_38',
      text: "I have to finish this by tomorrow.",
      category: "Stage 4",
      chunks: ["I have to finish this", "by tomorrow"],
      translation: "내일까지 이것을 끝내야 해요.",
    ),
    PracticeSentence(
      id: 'gdd_39',
      text: "All passengers must wear seat belts.",
      category: "Stage 4",
      chunks: ["All passengers", "must wear seat belts"],
      translation: "모든 승객은 안전벨트를 착용해야 합니다.",
    ),
    PracticeSentence(
      id: 'gdd_40',
      text: "I might be late.",
      category: "Stage 4",
      chunks: ["I might", "be late"],
      translation: "늦을지도 몰라요.",
    ),
    PracticeSentence(
      id: 'gdd_41',
      text: "I'm planning to work out after work.",
      category: "Stage 5",
      chunks: ["I'm planning to", "work out after work"],
      translation: "퇴근 후에 운동할 계획입니다.",
    ),
    PracticeSentence(
      id: 'gdd_42',
      text: "I think it's okay.",
      category: "Stage 5",
      chunks: ["I think", "it's okay"],
      translation: "괜찮은 것 같아요.",
    ),
    PracticeSentence(
      id: 'gdd_43',
      text: "How do I use this?",
      category: "Stage 5",
      chunks: ["How do I", "use this"],
      translation: "이것은 어떻게 사용하나요?",
    ),
    PracticeSentence(
      id: 'gdd_44',
      text: "What time do you get off work?",
      category: "Stage 5",
      chunks: ["What time", "do you get off work"],
      translation: "몇 시에 퇴근하세요?",
    ),
    PracticeSentence(
      id: 'gdd_45',
      text: "Who do you respect the most?",
      category: "Stage 5",
      chunks: ["Who do you respect", "the most"],
      translation: "누구를 가장 존경하나요?",
    ),
    PracticeSentence(
      id: 'gdd_46',
      text: "Did you have lunch?",
      category: "Stage 5",
      chunks: ["Did you have", "lunch"],
      translation: "점심 먹었어요?",
    ),
    PracticeSentence(
      id: 'gdd_47',
      text: "I just woke up.",
      category: "Stage 5",
      chunks: ["I just", "woke up"],
      translation: "방금 일어났어요.",
    ),
    PracticeSentence(
      id: 'gdd_48',
      text: "It's hard to get up early.",
      category: "Stage 5",
      chunks: ["It's hard to", "get up early"],
      translation: "일찍 일어나는 것은 힘들어요.",
    ),
    PracticeSentence(
      id: 'gdd_49',
      text: "It's easy to learn online.",
      category: "Stage 5",
      chunks: ["It's easy to", "learn online"],
      translation: "온라인으로 배우는 것은 쉬워요.",
    ),
    PracticeSentence(
      id: 'gdd_50',
      text: "It's time to go to bed.",
      category: "Stage 5",
      chunks: ["It's time", "to go to bed"],
      translation: "잠자리에 들 시간입니다.",
    ),
    PracticeSentence(
      id: 'gdd_51',
      text: "I feel like staying at home today.",
      category: "Stage 5",
      chunks: ["I feel like", "staying at home today"],
      translation: "오늘은 집에 있고 싶어요.",
    ),
    PracticeSentence(
      id: 'gdd_52',
      text: "I just wanted to say hello.",
      category: "Stage 5",
      chunks: ["I just wanted to", "say hello"],
      translation: "그냥 인사하고 싶었어요.",
    ),
    PracticeSentence(
      id: 'gdd_53',
      text: "I'm not sure if this is right or not.",
      category: "Stage 5",
      chunks: ["I'm not sure if", "this is right or not"],
      translation: "이것이 맞는지 잘 모르겠어요.",
    ),
    PracticeSentence(
      id: 'gdd_54',
      text: "I'm ready to change my life.",
      category: "Stage 5",
      chunks: ["I'm ready to", "change my life"],
      translation: "내 삶을 바꿀 준비가 되었습니다.",
    ),
    PracticeSentence(
      id: 'gdd_55',
      text: "You must be joking.",
      category: "Stage 5",
      chunks: ["You must", "be joking"],
      translation: "농담이시겠죠.",
    ),
    PracticeSentence(
      id: 'gdd_56',
      text: "I'm used to getting up early.",
      category: "Stage 5",
      chunks: ["I'm used to", "getting up early"],
      translation: "일찍 일어나는 것에 익숙해요.",
    ),
    PracticeSentence(
      id: 'gdd_57',
      text: "I already know that.",
      category: "Sub Mission A",
      chunks: ["I already", "know that"],
      translation: "그건 이미 알고 있어요.",
    ),
    PracticeSentence(
      id: 'gdd_58',
      text: "I'm still tired.",
      category: "Sub Mission A",
      chunks: ["I'm still", "tired"],
      translation: "여전히 피곤해요.",
    ),
    PracticeSentence(
      id: 'gdd_59',
      text: "I like coffee too.",
      category: "Sub Mission A",
      chunks: ["I like coffee", "too"],
      translation: "저도 커피를 좋아해요.",
    ),
    PracticeSentence(
      id: 'gdd_60',
      text: "Me too.",
      category: "Sub Mission A",
      chunks: ["Me", "too"],
      translation: "저도요.",
    ),
    PracticeSentence(
      id: 'gdd_61',
      text: "It takes about 10 minutes.",
      category: "Sub Mission A",
      chunks: ["It takes", "about 10 minutes"],
      translation: "대략 10분 정도 걸립니다.",
    ),
    PracticeSentence(
      id: 'gdd_62',
      text: "After work!",
      category: "Sub Mission A",
      chunks: ["After", "work!"],
      translation: "퇴근 후에!",
    ),
    PracticeSentence(
      id: 'gdd_63',
      text: "Three hours ago!",
      category: "Sub Mission A",
      chunks: ["Three hours", "ago!"],
      translation: "3시간 전에!",
    ),
    PracticeSentence(
      id: 'gdd_64',
      text: "In two hours!",
      category: "Sub Mission A",
      chunks: ["In two", "hours!"],
      translation: "2시간 후에!",
    ),
    PracticeSentence(
      id: 'gdd_65',
      text: "A few days ago!",
      category: "Sub Mission A",
      chunks: ["A few", "days ago!"],
      translation: "며칠 전에!",
    ),
    PracticeSentence(
      id: 'gdd_66',
      text: "Can I leave my bags until check in?",
      category: "Sub Mission B",
      chunks: ["Can I leave my bags", "until check in?"],
      translation: "체크인 전까지 가방을 맡겨도 될까요?",
    ),
    PracticeSentence(
      id: 'gdd_67',
      text: "Something is wrong with my room.",
      category: "Sub Mission B",
      chunks: ["Something is wrong", "with my room."],
      translation: "방에 문제가 좀 있어요.",
    ),
    PracticeSentence(
      id: 'gdd_68',
      text: "What time is breakfast served?",
      category: "Sub Mission B",
      chunks: ["What time is", "breakfast served?"],
      translation: "아침 식사는 몇 시에 제공되나요?",
    ),
    PracticeSentence(
      id: 'gdd_69',
      text: "I have a sore throat.",
      category: "Sub Mission B",
      chunks: ["I have", "a sore throat."],
      translation: "목이 아파요.",
    ),
    PracticeSentence(
      id: 'gdd_70',
      text: "How do I take this medicine?",
      category: "Sub Mission B",
      chunks: ["How do I take", "this medicine?"],
      translation: "이 약은 어떻게 복용하나요?",
    ),
    PracticeSentence(
      id: 'gdd_71',
      text: "Can I see the menu, please?",
      category: "Sub Mission C",
      chunks: ["Can I see the menu", "please?"],
      translation: "메뉴판 좀 볼 수 있을까요?",
    ),
    PracticeSentence(
      id: 'gdd_72',
      text: "Could you take a picture for us?",
      category: "Sub Mission C",
      chunks: ["Could you take a picture", "for us?"],
      translation: "사진 좀 찍어주시겠어요?",
    ),
    PracticeSentence(
      id: 'gdd_73',
      text: "Would you like to have dinner with us?",
      category: "Sub Mission C",
      chunks: ["Would you like to", "have dinner with us?"],
      translation: "저희와 저녁 같이 하실래요?",
    ),
    PracticeSentence(
      id: 'gdd_74',
      text: "I'd like to make a reservation.",
      category: "Sub Mission C",
      chunks: ["I'd like to", "make a reservation."],
      translation: "예약하고 싶습니다.",
    ),
    PracticeSentence(
      id: 'gdd_75',
      text: "Can you call me back later?",
      category: "Sub Mission C",
      chunks: ["Can you call me", "back later?"],
      translation: "나중에 다시 전화해 주시겠어요?",
    ),
    PracticeSentence(
      id: 'gdd_76',
      text: "I'm here to see my daughter.",
      category: "Sub Mission C",
      chunks: ["I'm here to", "see my daughter."],
      translation: "딸을 만나러 왔습니다.",
    ),
    PracticeSentence(
      id: 'gdd_77',
      text: "Do I need to take out my laptop?",
      category: "Sub Mission C",
      chunks: ["Do I need to", "take out my laptop?"],
      translation: "노트북을 꺼내야 하나요?",
    ),
    PracticeSentence(
      id: 'gdd_78',
      text: "Excuse me, why is the flight delayed?",
      category: "Sub Mission C",
      chunks: ["Excuse me", "why is the flight delayed?"],
      translation: "실례지만 비행기가 왜 지연되나요?",
    ),
    PracticeSentence(
      id: 'gdd_79',
      text: "Which way is gate 25?",
      category: "Sub Mission C",
      chunks: ["Which way is", "gate 25?"],
      translation: "25번 게이트가 어느 쪽인가요?",
    ),
    PracticeSentence(
      id: 'gdd_80',
      text: "I can't find one of my bags.",
      category: "Sub Mission C",
      chunks: ["I can't find", "one of my bags."],
      translation: "제 가방 중 하나를 찾을 수 없어요.",
    ),
    PracticeSentence(
      id: 'gdd_81',
      text: "For two, how long is the wait?",
      category: "Sub Mission C",
      chunks: ["For two", "how long is the wait?"],
      translation: "두 명인데 얼마나 기다려야 하나요?",
    ),
    PracticeSentence(
      id: 'gdd_82',
      text: "Can you make this without cilantro?",
      category: "Sub Mission C",
      chunks: ["Can you make this", "without cilantro?"],
      translation: "고수 빼고 만들어 주실 수 있나요?",
    ),
    PracticeSentence(
      id: 'gdd_83',
      text: "Can I get the dressing on the side?",
      category: "Sub Mission C",
      chunks: ["Can I get the dressing", "on the side?"],
      translation: "드레싱은 따로 주실 수 있나요?",
    ),
    PracticeSentence(
      id: 'gdd_84',
      text: "Do you have decaf?",
      category: "Sub Mission C",
      chunks: ["Do you have", "decaf?"],
      translation: "디카페인 음료 있나요?",
    ),
    PracticeSentence(
      id: 'gdd_85',
      text: "To go, please.",
      category: "Sub Mission C",
      chunks: ["To go", "please."],
      translation: "포장해 주세요.",
    ),
    PracticeSentence(
      id: 'gdd_86',
      text: "Can I get a box?",
      category: "Sub Mission C",
      chunks: ["Can I get", "a box?"],
      translation: "포장 상자(용기) 좀 주시겠어요?",
    ),
    PracticeSentence(
      id: 'gdd_87',
      text: "How long will it take?",
      category: "Sub Mission C",
      chunks: ["How long", "will it take?"],
      translation: "얼마나 걸릴까요?",
    ),
    PracticeSentence(
      id: 'gdd_88',
      text: "Could you help me with my bags?",
      category: "Sub Mission C",
      chunks: ["Could you help me", "with my bags?"],
      translation: "제 가방 좀 도와주시겠어요?",
    ),
    PracticeSentence(
      id: 'gdd_89',
      text: "I'll get off here, please.",
      category: "Sub Mission C",
      chunks: ["I'll get off", "here, please."],
      translation: "여기서 내릴게요.",
    ),
    PracticeSentence(
      id: 'gdd_90',
      text: "Is this bus bound for City Hall?",
      category: "Sub Mission C",
      chunks: ["Is this bus", "bound for City Hall?"],
      translation: "이 버스 시청행인가요?",
    ),
    PracticeSentence(
      id: 'gdd_91',
      text: "Where can I buy tickets?",
      category: "Sub Mission C",
      chunks: ["Where can I", "buy tickets?"],
      translation: "표는 어디서 사나요?",
    ),
    PracticeSentence(
      id: 'gdd_92',
      text: "I'm just looking around.",
      category: "Sub Mission C",
      chunks: ["I'm just", "looking around."],
      translation: "그냥 둘러보는 중이에요.",
    ),
    PracticeSentence(
      id: 'gdd_93',
      text: "Do you have this in another size?",
      category: "Sub Mission C",
      chunks: ["Do you have this", "in another size?"],
      translation: "이거 다른 사이즈로도 있나요?",
    ),
    PracticeSentence(
      id: 'gdd_94',
      text: "Do you have this in another color?",
      category: "Sub Mission C",
      chunks: ["Do you have this", "in another color?"],
      translation: "이거 다른 색상으로도 있나요?",
    ),
    PracticeSentence(
      id: 'gdd_95',
      text: "Can I get a tax refund?",
      category: "Sub Mission C",
      chunks: ["Can I get", "a tax refund?"],
      translation: "텍스 리펀드(세금 환급) 가능한가요?",
    ),
    PracticeSentence(
      id: 'gdd_96',
      text: "Is this the final price?",
      category: "Sub Mission C",
      chunks: ["Is this the", "final price?"],
      translation: "이게 최종 가격인가요?",
    ),
    PracticeSentence(
      id: 'gdd_97',
      text: "I'd like to exchange this.",
      category: "Sub Mission C",
      chunks: ["I'd like to", "exchange this."],
      translation: "이거 교환하고 싶어요.",
    ),
    PracticeSentence(
      id: 'gdd_98',
      text: "I'd like to refund this.",
      category: "Sub Mission C",
      chunks: ["I'd like to", "refund this."],
      translation: "이거 환불하고 싶어요.",
    ),
    PracticeSentence(
      id: 'gdd_99',
      text: "Could you call a taxi for me?",
      category: "Sub Mission C",
      chunks: ["Could you call", "a taxi for me?"],
      translation: "택시 좀 불러주시겠어요?",
    ),
    PracticeSentence(
      id: 'gdd_100',
      text: "Can I get a late check-out?",
      category: "Sub Mission C",
      chunks: ["Can I get", "a late check-out?"],
      translation: "레이트 체크아웃이 가능한가요?",
    ),
    PracticeSentence(
      id: 'gdd_101',
      text: "I have lost my key.",
      category: "Sub Mission D",
      chunks: ["I have lost", "my key."],
      translation: "열쇠를 잃어버렸어요.",
    ),
    PracticeSentence(
      id: 'gdd_102',
      text: "I have my key lost.",
      category: "Sub Mission D",
      chunks: ["I have my key", "lost."],
      translation: "제 열쇠가 분실된 상태예요.",
    ),
    PracticeSentence(
      id: 'gdd_103',
      text: "It feels a bit chilly today.",
      category: "Sub Mission D",
      chunks: ["It feels", "a bit chilly today."],
      translation: "오늘 날씨가 약간 쌀쌀하네요.",
    ),
    PracticeSentence(
      id: 'gdd_104',
      text: "I was wondering if you could help me.",
      category: "Sub Mission D",
      chunks: ["I was wondering if", "you could help me."],
      translation: "저를 좀 도와주실 수 있으신가요?",
    ),
    PracticeSentence(
      id: 'gdd_105',
      text: "I should have booked the tickets.",
      category: "Sub Mission D",
      chunks: ["I should have", "booked the tickets."],
      translation: "표를 미리 예약했어야 했는데 말이죠.",
    ),
    PracticeSentence(
      id: 'gdd_106',
      text: "As far as I know, the meeting is canceled.",
      category: "Sub Mission D",
      chunks: ["As far as I know", "the meeting is canceled."],
      translation: "제가 알기로는 회의가 취소되었습니다.",
    ),
    PracticeSentence(
      id: 'gdd_107',
      text: "I'm sick and tired of eating the same food.",
      category: "Sub Mission D",
      chunks: ["I'm sick and tired of", "eating the same food."],
      translation: "맨날 똑같은 음식을 먹어서 아주 지긋지긋해요.",
    ),
    PracticeSentence(
      id: 'gdd_108',
      text: "The point is we don't have much time.",
      category: "Sub Mission D",
      chunks: ["The point is", "we don't have much time."],
      translation: "핵심은 우리에게 시간이 별로 없다는 것입니다.",
    ),
    PracticeSentence(
      id: 'gdd_109',
      text: "No way, that's impossible.",
      category: "Sub Mission D",
      chunks: ["No way", "that's impossible."],
      translation: "말도 안 돼요, 그건 불가능해요.",
    ),
    PracticeSentence(
      id: 'gdd_110',
      text: "If I caught the star, I would give it to you.",
      category: "Sub Mission D",
      chunks: ["If I caught the star", "I would give it to you."],
      translation: "만약 내가 저 별을 딴다면, 당신에게 줄 텐데요.",
    ),
    PracticeSentence(
      id: 'gdd_111',
      text: "Not all of them like it.",
      category: "Stage 6",
      chunks: ["Not all of them", "like it."],
      translation: "그들 모두가 좋아하는 것은 아닙니다.",
    ),
    PracticeSentence(
      id: 'gdd_112',
      text: "Yes, I have already seen it.",
      category: "Stage 6",
      chunks: ["Yes, I have", "already seen it."],
      translation: "네, 이미 봤어요.",
    ),
    PracticeSentence(
      id: 'gdd_113',
      text: "I hear mom singing in the kitchen.",
      category: "Stage 6",
      chunks: ["I hear mom singing", "in the kitchen."],
      translation: "엄마가 주방에서 노래하시는 소리가 들려요.",
    ),
    PracticeSentence(
      id: 'gdd_114',
      text: "We will go unless it rains.",
      category: "Stage 6",
      chunks: ["We will go", "unless it rains."],
      translation: "비가 오지 않는 한 우리는 갈 것입니다.",
    ),
    PracticeSentence(
      id: 'gdd_115',
      text: "He grew up to be a doctor.",
      category: "Stage 6",
      chunks: ["He grew up", "to be a doctor."],
      translation: "그는 자라서 의사가 되었습니다.",
    ),
    PracticeSentence(
      id: 'gdd_116',
      text: "The more I read, the smarter I get.",
      category: "Stage 6",
      chunks: ["The more I read", "the smarter I get."],
      translation: "책을 읽으면 읽을수록 더 똑똑해집니다.",
    ),
  ];

  /// Loads sentences from SharedPreferences. If empty, loads defaults and saves them.
  static Future<List<PracticeSentence>> loadSentences() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_storageKey);
    
    if (jsonStr == null || jsonStr.trim().isEmpty) {
      // First run: save defaults
      await saveSentences(_defaultSentences);
      return _defaultSentences;
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      final List<PracticeSentence> loaded = [];
      for (int i = 0; i < decoded.length; i++) {
        final Map<String, dynamic> item = decoded[i];
        loaded.add(PracticeSentence.fromJson(item, 'loaded_${i + 1}'));
      }
      return loaded;
    } catch (e) {
      // If parsing fails, fall back to defaults
      await saveSentences(_defaultSentences);
      return _defaultSentences;
    }
  }

  /// Saves the list of sentences to SharedPreferences.
  static Future<void> saveSentences(List<PracticeSentence> sentences) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList = sentences.map((s) => s.toJson()).toList();
    final String jsonStr = jsonEncode(jsonList);
    await prefs.setString(_storageKey, jsonStr);
  }

  /// Adds a single sentence to the database.
  static Future<List<PracticeSentence>> addSentence(PracticeSentence sentence) async {
    final sentences = await loadSentences();
    // Prevent duplicate IDs or texts if necessary, but simple add is fine.
    sentences.add(sentence);
    await saveSentences(sentences);
    return sentences;
  }

  /// Deletes a sentence by its ID.
  static Future<List<PracticeSentence>> deleteSentence(String id) async {
    final sentences = await loadSentences();
    sentences.removeWhere((s) => s.id == id);
    await saveSentences(sentences);
    return sentences;
  }

  /// Resets the storage database back to the default 5 sentences.
  static Future<List<PracticeSentence>> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    return loadSentences();
  }

  /// Overwrites the database with a list parsed from JSON string.
  /// Throws FormatException if formatting is incorrect.
  static Future<List<PracticeSentence>> importFromJson(String rawJson) async {
    final decoded = jsonDecode(rawJson);
    if (decoded is! List) {
      throw const FormatException('JSON root must be an array of objects');
    }

    final List<PracticeSentence> importedList = [];
    for (int i = 0; i < decoded.length; i++) {
      final item = decoded[i];
      if (item is! Map<String, dynamic>) {
        throw FormatException('Element at index $i is not a JSON object');
      }
      
      // Auto generate ID if not present
      final String generatedId = DateTime.now().millisecondsSinceEpoch.toString() + '_$i';
      importedList.add(PracticeSentence.fromJson(item, generatedId));
    }

    if (importedList.isEmpty) {
      throw const FormatException('Empty list of sentences provided');
    }

    await saveSentences(importedList);
    return importedList;
  }

  /// Exports current database of sentences to JSON string formatted with indentation.
  static String exportToJson(List<PracticeSentence> sentences) {
    final List<Map<String, dynamic>> jsonList = sentences.map((s) => s.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(jsonList);
  }
}
