import 'package:html/parser.dart' as htmlparser;
import 'package:html/dom.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:namaz_vakti_app/books/shared/models/index_item_model.dart';

class HtmlParser {
  static List<Map<String, dynamic>> parseHtmlString(String htmlString) {
    var unescape = HtmlUnescape();
    String decodedHtml = unescape.convert(htmlString);

    final document = htmlparser.parse('<html><body>$decodedHtml</body></html>');
    List<Map<String, dynamic>> formattedElements = [];
    Map<String, dynamic>? currentParagraph;

    void processNode(Node node) {
      if (node is Element && node.localName == 'img') {
        // Resim elementi bulundu
        if (currentParagraph != null) {
          formattedElements.add(currentParagraph!);
          currentParagraph = null;
        }

        String? src = node.attributes['src'];
        if (src != null) {
          formattedElements.add({
            'type': 'image',
            'src': src,
            'align': 'center',
          });
        }
        return;
      }

      if (node is Text) {
        String text = node.text.trim();
        if (text.isNotEmpty) {
          Element? parent = node.parent;
          String align = parent?.attributes['align'] ?? 'left';

          // Start a new paragraph only for elements with alignment
          if (parent?.attributes['align'] != null || currentParagraph == null) {
            if (currentParagraph != null) {
              formattedElements.add(currentParagraph!);
            }
            currentParagraph = {
              'type': 'text',
              'text': '',
              'align': align,
              'segments': <Map<String, dynamic>>[],
            };
          }

          // Add text segment with its bold status
          if (currentParagraph != null) {
            bool bold = parent?.localName == 'b' || parent?.parent?.localName == 'b';
            currentParagraph!['segments'].add({
              'text': text,
              'bold': bold,
            });
          }
        }
      } else if (node is Element) {
        if (node.localName == 'br' || node.localName == 'p') {
          if (currentParagraph != null) {
            formattedElements.add(currentParagraph!);
            currentParagraph = null;
          }
        }

        for (var child in node.nodes) {
          processNode(child);
        }
      }
    }

    document.body?.nodes.forEach(processNode);

    if (currentParagraph != null) {
      formattedElements.add(currentParagraph!);
    }

    // Combine segments into final text for text type elements
    return formattedElements.map((element) {
      if (element['type'] == 'image') {
        return element;
      }

      String combinedText = element['segments'].map((segment) => segment['text']).join(' ');

      return {
        'type': 'text',
        'text': combinedText,
        'align': element['align'],
        'bold': false,
        'segments': element['segments'],
      };
    }).toList();
  }

  static List<IndexItem> parseIndexHtml(String htmlString) {
    final document = htmlparser.parse(htmlString);
    List<IndexItem> indexItems = [];

    // First try to get the book title
    var bookTitleElement = document.querySelector('.booktitle');
    if (bookTitleElement != null) {
      // Add the book title as the first item in the index
      indexItems.add(IndexItem(
        pageNumber: 0,
        title: bookTitleElement.text.trim(),
      ));
    }

    var rows = document.querySelectorAll('tr');
    for (var row in rows) {
      var indexNoTd = row.querySelector('.indexno');
      var indexTextTd = row.querySelector('.indextext');

      if (indexNoTd != null && indexTextTd != null) {
        int? pageNumber = int.tryParse(indexNoTd.text);
        if (pageNumber != null) {
          indexItems.add(IndexItem(
            pageNumber: pageNumber,
            title: indexTextTd.text.trim(),
          ));
        }
      }
    }

    return indexItems;
  }
}
