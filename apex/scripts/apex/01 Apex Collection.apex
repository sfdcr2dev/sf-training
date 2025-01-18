List<String> colors = new List<String>{ 'red', 'green', 'blue' };
List<String> moreColors = new List<String>();

moreColors.add('orange');
moreColors.add('purple');

String color1 = moreColors.get(0);
String color2 = moreColors[0];

System.debug(color1);
System.debug(color2);

for (Integer i = 0; i < colors.size(); i++) {
    System.debug(colors[i]);
}
