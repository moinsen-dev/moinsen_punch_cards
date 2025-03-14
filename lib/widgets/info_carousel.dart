import 'package:flutter/material.dart';

class InfoCarousel extends StatefulWidget {
  const InfoCarousel({super.key});

  @override
  State<InfoCarousel> createState() => _InfoCarouselState();
}

class _InfoCarouselState extends State<InfoCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<CarouselItem> _items = [
    CarouselItem(
      title: 'Welcome to MoinsenPunchcard',
      description:
          'Your journey into the fascinating world of punch cards begins here. Swipe to learn about the history and significance of this revolutionary technology.',
      icon: Icons.waves,
    ),
    CarouselItem(
      title: 'What is Wipe Coding?',
      description:
          'Wipe coding is a modern technique that uses computer vision to process physical punch cards. By "wiping" across a punch card with your device\'s camera, MoinsenPunchcard can read and interpret the holes, bringing this historic technology into the digital age.',
      icon: Icons.camera_alt,
    ),
    CarouselItem(
      title: 'The Birth of Punch Cards',
      description:
          'In 1890, Herman Hollerith revolutionized data processing by creating punch cards for the U.S. census. Each card could store data through patterns of holes, leading to the birth of automated data processing.',
      icon: Icons.history_edu,
    ),
    CarouselItem(
      title: 'IBM and the 80-Column Era',
      description:
          'IBM standardized the 80-column punch card in the 1920s. This format became so influential that it shaped early computer displays and still influences some software interfaces today.',
      icon: Icons.view_column,
    ),
    CarouselItem(
      title: 'How Punch Cards Work',
      description:
          'Each punch card contains a grid of potential hole positions. The presence or absence of holes in specific positions represents data - numbers, letters, or instructions for early computers.',
      icon: Icons.grid_on,
    ),
    CarouselItem(
      title: 'Legacy and Impact',
      description:
          'While no longer used for data storage, punch cards laid the foundation for modern computing. Their influence can still be seen in programming conventions and data processing concepts.',
      icon: Icons.memory,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: _items.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _items[index].icon,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _items[index].title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _items[index].description,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _items.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _currentPage == index
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CarouselItem {
  final String title;
  final String description;
  final IconData icon;

  CarouselItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}
