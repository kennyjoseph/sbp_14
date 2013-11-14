import java.io.IOException;
import java.net.UnknownHostException;
import java.util.ArrayList;

import com.mongodb.MongoClient;


public class main {

	
	
	public static void main(String args[]) throws InterruptedException, UnknownHostException{
		String configFile = args[0];
		String outputDirectory = args[1];
		if(!outputDirectory.endsWith("/")){
			outputDirectory += "/";
		}
		
		long timeToRunFor = Long.valueOf(args[2])*60*1000;
		System.out.println("Running w/ config: "+ configFile + ", outputDir: "+ outputDirectory +", for "+args[2] + " minutes");
		//TODO: for the paper, we wanted to run iterations for the keywords,
		//but they're pretty easy to put into a command line arg 
		
		MongoClient mongoClient = new MongoClient();
		ArrayList<ValidUser> users = null;
		try {
			users = ValidUser.getUsersFromConfig(configFile);
		} catch (IOException e) {
			e.printStackTrace();
		}

		for(int i = 0; i < 2; i++){
			new KeywordTester(users,outputDirectory, false,false, timeToRunFor, mongoClient, i,  "the");
			new KeywordTester(users,outputDirectory, false,false, timeToRunFor, mongoClient, i,  "be");
			new KeywordTester(users,outputDirectory, false,false, timeToRunFor, mongoClient, i, "i");
			//Test with all three
			new KeywordTester(users,outputDirectory, false,false, timeToRunFor, mongoClient, 2, "the","be","i");
			//Test with nonsense term
			new KeywordTester(users,outputDirectory, false,false, timeToRunFor, mongoClient, i, "the","thisisanonsenseterm");
			//Try adding username on to each stream
			new KeywordTester(users,outputDirectory, true,false, timeToRunFor, mongoClient, i, "the");
			//Try staggering
			new KeywordTester(users,outputDirectory, false, true, timeToRunFor, mongoClient, i, "the");
		}
		
	}
}
