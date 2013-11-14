import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;



public class ValidUser {

	public String consumerKey = "";
	public String consumerSecret = "";
	public String accessToken = "";
	public String accessTokenSecret = "";
	public String name = "";
	public ValidUser(String name, String cKey, String cSecret, String aToken, String aSecret){
		this.name = name;
		consumerKey = cKey;
		consumerSecret = cSecret;
		accessToken = aToken;
		accessTokenSecret = aSecret;
	}
	public static ArrayList<ValidUser> getUsersFromConfig(String configFile) throws IOException {
		ArrayList<ValidUser> users = new ArrayList<ValidUser>();
		BufferedReader reader = new BufferedReader(new FileReader(configFile));
		String name= "";
		//TODO: Add some error checking
		while((name = reader.readLine()) != null){
			String consumerKey = reader.readLine();
			String consumerSecret = reader.readLine();
			String accessToken = reader.readLine();
			String accessTokenSecret = reader.readLine();
			users.add(new ValidUser(name, consumerKey,consumerSecret,accessToken,accessTokenSecret));
			System.out.println("created user: " + name);
			reader.readLine();
		}
		reader.close();
		return users;
	}
}
