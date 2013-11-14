/**
 * Copyright 2013 Twitter, Inc.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.lang3.StringUtils;

import com.mongodb.DB;
import com.mongodb.MongoClient;


public class KeywordTester {
	ArrayList<KeywordSampler> samplers = new ArrayList<KeywordSampler>();
	String outputDirectory;
	
	public KeywordTester(List<ValidUser> users,
						String outputDirectory,
						boolean addUsernameAsKeyword,
						boolean stagger,
						long runDuration, 
						MongoClient mongoClient, 
						int iteration,
						String ... keywords) throws InterruptedException{
		
		this.outputDirectory = outputDirectory;
		String directory = StringUtils.join(keywords,"_").replace(" ", "_") +
							"_"+ String.valueOf(addUsernameAsKeyword) +
							"_"+ String.valueOf(stagger) + 
							"_" + String.valueOf(iteration);
		
		File theDir = new File(outputDirectory+ directory);
		if (!theDir.exists()) {
			System.out.println("creating directory: " + directory);
			boolean result = theDir.mkdir();  

			if(result) {    
				System.out.println("DIR created");  
			}
		}
		for(ValidUser u: users){
			DB db = mongoClient.getDB(u.name);
			samplers.add(new KeywordSampler(u, addUsernameAsKeyword, db, outputDirectory, directory,keywords));
		}

		for(KeywordSampler k: samplers){
			//Tried staggering runtimes.  Didn't affect anything in any obvious way
			if(stagger){
				Thread.sleep(150);
			}
			k.start();
		}
		Thread.sleep(runDuration);
		for(KeywordSampler k: samplers){
			System.out.println("stopping");
			k.stop();
		}
	}
}