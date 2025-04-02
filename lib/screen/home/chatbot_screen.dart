import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  bool _showChat = false;
  bool _isLogoLoaded = false;  // Add this line

  final _textController = TextEditingController();
  List<ChatMessage> _messages = [];
  final List<String> _allSuggestedQuestions = [
    "What are your services?",
    "What is your location?",
    "Do you provide 24/7 support?",
    "How can I book a car?",
    "How can I become a host?",
    "How can I host a car?",
    "How can I update my existing car's details?",
    "How can I see my booking?",
    "How can I see my trips detail?",
    "What is the payment method?",
    "Which documents are required to book a car?",
    "Which documents are required to host a car?",
    "If I extend my trip, what is the process?",
    "Is any discount available?",
    "In your app, how can I see the car details?",
    "How can I see the car location?",
    "How can I see the car availability?",
    "How can I see the car price?",
    "How can I see the car rating?",
    "How can I complete my trip?",
    "Is all car have insurance?",
    "How can I change my booking date?",
    "How can I cancel my booking?",
    "Is any cancellation policy?",
  ];
  List<String> _suggestedQuestions = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _messages = [
      ChatMessage(
        text: 'Hello User, How can I help you?',
        isSentByMe: false,
        time: _getCurrentTime(),
        sender: 'Chatbot',
      ),
    ];
    _suggestedQuestions = List.from(_allSuggestedQuestions); // Initialize suggested questions

    // Load the logo immediately and set _isLogoLoaded to true when done
    _loadImage().then((_) {
      setState(() {
        _isLogoLoaded = true;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  // Use a Future to simulate loading the image
  Future<void> _loadImage() async {
    // Simulate loading the image with a delay
    await Future.delayed(const Duration(milliseconds: 100)); // Adjust the delay as needed

    //  _isLogoLoaded will be set to true in the `initState` method after
    // the future completes, and the screen will be re-rendered with the logo.
  }


  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _getCurrentTime() {
    return DateFormat('hh:mm a').format(DateTime.now());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _showChat ? _buildChatScreen() : _buildStartChatScreen(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: _showChat
          ? Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.chat_bubble),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Chatbot'),
                    Text(
                      'Support Agent',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            )
          : const Text('Chat with us!'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      actions: const [],
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    );
  }

  Widget _buildStartChatScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 60.0, left: 20, right: 20, bottom: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Hello Nice to see you here! By pressing the \"Start chat\" button you agree to have your personal data processed as described in our Privacy Policy",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showChat = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text('Start chat'),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: CircleAvatar(
                backgroundColor: Colors.transparent,
                radius: 50,
                child: ClipOval(
                  child: _isLogoLoaded
                      ? Image.asset(
                          "assets/images/urbandrive logo.jpg",
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                        )
                      : const SizedBox(width: 100, height: 100), // Placeholder
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatScreen() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            reverse: false,
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return ChatBubble(message: message);
            },
          ),
        ),
        Container(
          height: 150.0,
          child: ListView.builder(
            scrollDirection: Axis.vertical,
            itemCount: _suggestedQuestions.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    _sendMessage(suggestedQuestion: _suggestedQuestions[index]);
                  },
                  child: Text(_suggestedQuestions[index]),
                ),
              );
            },
          ),
        ),
        _buildMessageInput(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Powered by Urban Drives',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Write a message',
                border: InputBorder.none,
              ),
              onChanged: (text) {
                _filterSuggestedQuestions(text);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              _sendMessage();
            },
          ),
        ],
      ),
    );
  }

  void _sendMessage({String? suggestedQuestion}) {
    final text = suggestedQuestion ?? _textController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add(ChatMessage(
          text: text,
          isSentByMe: true,
          time: _getCurrentTime(),
          sender: 'You',
        ));

        final botResponse = _getChatbotResponse(text);

        _messages.add(ChatMessage(
          text: botResponse,
          isSentByMe: false,
          time: _getCurrentTime(),
          sender: 'Chatbot',
        ));
        _scrollToBottom();
      });
      _textController.clear();
      _filterSuggestedQuestions('');
    }
  }

  String _getChatbotResponse(String question) {
    question = question.toLowerCase();

    List<String> lowerCaseAllQuestions =
        _allSuggestedQuestions.map((q) => q.toLowerCase()).toList();

    if (lowerCaseAllQuestions.contains(question)) {
      String originalQuestion = _allSuggestedQuestions[lowerCaseAllQuestions.indexOf(question)];

      if (originalQuestion == "What are your services?") {
        return "We offer a variety of services including car rentals and transport services.";
      } else if (originalQuestion == "What is your location?") {
        return "Our main office is located in downtown South Bopal, Ahmedabad. But we have locations in all over nation. What city do you live in?";
      } else if (originalQuestion == "Do you provide 24/7 support?") {
        return "Yes, we provide 24/7 support to all of our customers.";
      } else if (originalQuestion == "How can I book a car?") {
        return "To book a car, you can search and select the car you want to book. Then, you can select the dates and times you want to book the car for. Finally, you can confirm your booking by providing your payment information.";
      } else if (originalQuestion == "How can I become a host?") {
        return "In profile section, you can see the option to become a host. Click on that and fill the required details to become a host.";
      } else if (originalQuestion == "How can I host a car?") {
        return "To host a car, you need to have a car that you are willing to rent out. You can list your car on our platform by providing the required information about your car and setting the rental price.";
      } else if (originalQuestion == "How can I update my existing car's details?") {
        return "To update your existing car details at host side in my cars screen you can find the car whose details you want to update and click on that car card";
      } else if (originalQuestion == "How can I see my booking?") {
        return "To see your booking, you can go to the 'My Bookings' section on our app. Here, you can see all the details of your bookings including the car, dates, renter's details, total amount and times of the booking.";
      } else if (originalQuestion == "How can I see my trips detail?") {
        return "To see your trips details, you can go to the 'My Trips' section on our app. Here, you can see all the details of your trips in two section Ongoing Trips and Completed Trips and you can see the details of your trips.";
      } else if (originalQuestion == "What is the payment method?") {
        return "We accept all major credit and debit cards for payment. You can also use online payment methods like UPI, Netbanking, and bank transfers.";
      } else if (originalQuestion == "Which documents are required to book a car?") {
        return "To book a car, you need to provide a valid driving license images as proof of identity.";
      } else if (originalQuestion == "Which documents are required to host a car?") {
        return "To host a car, you need to provide car registration certificate, car insurance certificate, and car PUC certificate.";
      } else if (originalQuestion == "If I extend my trip, what is the process?") {
        return "If you want to extend your trip, you can do so by contacting our host of car. He/She will extend the trip for you by checking car's availability.";
      } else if (originalQuestion == "Is any discount available?") {
        return "Yes, we offer discounts on long-term bookings and for repeat customers. You can also check our Home Screen banner for any ongoing discounts.";
      } else if (originalQuestion == "In your app, how can I see the car details?") {
        return "To see the car details, you can click on the car card in the 'Car' section. Here, you can see all the details of the car including the car type, model, year, and rental price.";
      } else if (originalQuestion == "How can I see the car location?") {
        return "You can see the location of Car by tapping on card of car that will navigates you on Car Details Screen where you can see the location of car.";
      } else if (originalQuestion == "How can I see the car availability?") {
        return "You can see the availability of car by tapping on card of car that will navigates you on Car Details Screen where you can see the availability of car.";
      } else if (originalQuestion == "How can I see the car price?") {
        return "You can see the price of car by tapping on card of car that will navigates you on Car Details Screen where you can see the hourly price of car.";
      } else if (originalQuestion == "How can I see the car rating?") {
        return "You can see the rating of car by tapping on card of car that will navigates you on Car Details Screen where you can see the rating of car and also you can see average rating on card of car.";
      } else if (originalQuestion == "How can I complete my trip?") {
        return "To complete your trip, you can go to the 'My Trips' section in our app. Here, you can see all the details of your Ongoing trips in card format you can right swipe the card to complete the trip after that you can give the rating and review to that car.";
      } else if (originalQuestion == "Is all car have insurance?") {
        return "Yes, all cars listed on our platform have insurance.";
      } else if (originalQuestion == "How can I change my booking date?") {
        return "To change your booking date, you can contact our support team. They will help you to change the booking date.";
      } else if (originalQuestion == "How can I cancel my booking?") {
        return "There is no cancellation policy available for booking. Once you book the car, you can't cancel it.";
      } else if (originalQuestion == "Is any cancellation policy?") {
        return "There is no cancellation policy available in our platform. For more details you can contact our support team.";
      }
    }
    return "I am a chatbot, and I am still trying to learn new things. I don't have an answer to your question at this time. For further assistance, you can contact support.tds@gmail.com.";
  }

  void _filterSuggestedQuestions(String query) {
    setState(() {
      if (query.isEmpty) {
        _suggestedQuestions = List.from(_allSuggestedQuestions);
      } else {
        _suggestedQuestions = _allSuggestedQuestions
            .where((question) => question.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }
}

class ChatMessage {
  final String text;
  final bool isSentByMe;
  final String time;
  final String sender;

  ChatMessage({
    required this.text,
    required this.isSentByMe,
    required this.time,
    required this.sender,
  });
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isSentByMe ? Alignment.topRight : Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: message.isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!message.isSentByMe)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${message.sender} ${message.time}'),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.only(bottom: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      message.text,
                      style: const TextStyle(color: Colors.black),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.left,
                ),
              ),
            if (message.isSentByMe)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Visitor ' + message.time),
                  const Text(' Read'),
                ],
              )
          ],
        ),
      ),
    );
  }
}