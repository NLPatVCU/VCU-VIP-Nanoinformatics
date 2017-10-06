import pubmed_functions as pf
import json
import tensorflow as tf

def main():
    results = pf.search("fever")
    id_list = results['IdList']
    papers = pf.fetch_details(id_list)
    for paper in papers["PubmedArticle"]:
        print ("Title : %s \nAbstract: %s \n" % (paper["MedlineCitation"]["Article"]["ArticleTitle"], paper["MedlineCitation"]["Article"]["Abstract"]["AbstractText"][0]))

   # Uncomment to pretty print all data
    print json.dumps(papers["PubmedArticle"][0], indent=4)

if __name__ == '__main__':
    main()