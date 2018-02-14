import xml.etree.cElementTree as ET
import os
import json
import re


def cleanString(string):
    if string:
        strings_newline_removed = re.sub("\n", "", string)
        string_fix_spacing = re.sub("\s+", " ", strings_newline_removed)
        return string_fix_spacing
    return "Not Provided"


for dirpath, dirnames, files in os.walk("../Non-NanoPMC"):
    json_list = []
    for name in files:
        if name.lower().endswith('.xml'):
            file_name = os.path.join(dirpath, name)
            json_object = {}
            parsed_xml = ET.parse(file_name)
            root = parsed_xml.getroot()
            front = parsed_xml.find('front')
            meta = front.find("article-meta")


            for t in front.iter('article-title'):
                article_title = ''.join(t.itertext())

            pmid = "PMID Not Provided"
            for articleid in meta.findall('article-id'):
                if articleid.attrib.get('pub-id-type', 'default') == 'pmid':
                    pmid = articleid.text
            print(pmid)

            for title in root.iter('journal-title'):
                journal = title.text

            for abstract in root.iter('abstract'):
                p_section = abstract.find('p')
                if p_section is None:
                    content = ""
                    sections = abstract.findall('sec')
                    for section in sections:
                        p = section.find('p')
                        text = ''.join(p.itertext())
                        content += text
                    theabstract = content
                else:
                    text = ''.join(p_section.itertext())
                    theabstract = text

            json_object["PMID"] = pmid
            json_object["journal"] = journal
            json_object["abstract"] = cleanString(theabstract)
            json_object['title'] = cleanString(article_title)
            json_list.append(json_object)

    complete_path = os.path.join("../JSON", "Non-Nano.json")
    with open(complete_path, "w") as jsonlfile:
        jsonlfile.write(json.dumps(json_list, indent=4, separators=(',', ":")))
