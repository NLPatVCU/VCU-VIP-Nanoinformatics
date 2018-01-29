import java.io.File;
import weka.core.Instances;
import weka.core.converters.ArffSaver;
import weka.core.converters.ConverterUtils;
import weka.filters.Filter;
import weka.filters.unsupervised.instance.SparseToNonSparse;

/**
 * 
 * Converts sparse to non-sparse data formats, specify input path, output
 * path in sparseLocation, nonSparseLocation variables.
 * 
 */
public class SparseToNonSparseConverter {
    public static void main(String[] args) throws Exception {
       // String[] featureType = new String[]{"_o", "_om","_omt","_omt","_omtp","_omtpc", "_omtpc"};
        
        try {
            String sparseLocation = args[0];
            ConverterUtils.DataSource source = new ConverterUtils.DataSource(sparseLocation);

            Instances data = source.getDataSet();
            data.setClassIndex(data.numAttributes() - 1);

            SparseToNonSparse filter = new SparseToNonSparse();
            filter.setInputFormat(data);

            Instances nonsparse = Filter.useFilter(data, filter);

            ArffSaver saver = new ArffSaver();
            saver.setInstances(nonsparse);

            String nonSparseLocation = args[1];
            saver.setFile(new File(nonSparseLocation));
            saver.setDestination(new File(nonSparseLocation));   // **not** necessary in 3.5.4 and later
            saver.writeBatch();
        } catch (Exception e) {
            e.printStackTrace();
        }

    }
}
