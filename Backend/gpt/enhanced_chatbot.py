from transformers import AutoTokenizer, AutoModelForCausalLM, pipeline
import torch
import re

class VoiceUPIChatbot:
    def __init__(self, model_path):
        self.tokenizer = AutoTokenizer.from_pretrained(model_path)
        self.model = AutoModelForCausalLM.from_pretrained(model_path)
        
        # Enhanced generation parameters
        self.generation_config = {
            "max_length": 256,
            "num_return_sequences": 1,
            "temperature": 0.7,  # Balanced creativity
            "top_p": 0.9,        # Nucleus sampling
            "top_k": 50,         # Top-k sampling
            "do_sample": True,
            "pad_token_id": self.tokenizer.eos_token_id,
            "repetition_penalty": 1.1,  # Reduce repetition
        }
    
    def generate_response(self, user_input):
        """Generate enhanced responses with better control"""
        # Clean and format input
        user_input = self.clean_input(user_input)
        
        # Create conversation prompt
        prompt = f"<|user|>{user_input}<|assistant|>"
        
        # Tokenize input
        inputs = self.tokenizer.encode(prompt, return_tensors="pt")
        
        # Generate response
        with torch.no_grad():
            outputs = self.model.generate(
                inputs,
                **self.generation_config
            )
        
        # Decode and clean response
        full_response = self.tokenizer.decode(outputs[0], skip_special_tokens=True)
        assistant_response = self.extract_assistant_response(full_response, prompt)
        
        return self.post_process_response(assistant_response)
    
    def clean_input(self, text):
        """Clean user input"""
        text = text.strip()
        text = re.sub(r'\s+', ' ', text)  # Remove extra whitespace
        return text
    
    def extract_assistant_response(self, full_text, prompt):
        """Extract only the assistant's response"""
        try:
            # Remove the prompt from the response
            response = full_text.replace(prompt, "").strip()
            
            # Find the assistant response between tokens
            if "<|assistant|>" in response:
                response = response.split("<|assistant|>")[-1]
            
            if "<|endofturn|>" in response:
                response = response.split("<|endofturn|>")[0]
            
            if "<|user|>" in response:
                response = response.split("<|user|>")[0]
            
            return response.strip()
            
        except Exception as e:
            return "I'm sorry, I didn't understand that. Could you please rephrase?"
    
    def post_process_response(self, response):
        """Clean and validate the response"""
        if not response or len(response.strip()) < 3:
            return "I'm here to help with your VoiceUPI needs. What would you like to do?"
        
        # Remove incomplete sentences
        if not response.endswith(('.', '!', '?')):
            sentences = response.split('.')
            if len(sentences) > 1:
                response = '.'.join(sentences[:-1]) + '.'
            else:
                response += '.'
        
        # Ensure response is relevant to VoiceUPI
        voiceupi_keywords = ['upi', 'payment', 'money', 'send', 'transaction', 'bank', 'voice', 'balance']
        if not any(keyword in response.lower() for keyword in voiceupi_keywords):
            if any(greeting in response.lower() for greeting in ['hello', 'hi', 'hey', 'good']):
                response += " How can I help you with your VoiceUPI payments today?"
        
        return response
    
    def get_contextual_response(self, user_input, conversation_history=None):
        """Generate response with conversation context"""
        if conversation_history:
            # Include recent conversation context
            context = ""
            for turn in conversation_history[-3:]:  # Last 3 turns
                context += f"<|user|>{turn['user']}<|assistant|>{turn['assistant']}"
            
            prompt = f"{context}<|user|>{user_input}<|assistant|>"
        else:
            prompt = f"<|user|>{user_input}<|assistant|>"
        
        # Generate with context
        inputs = self.tokenizer.encode(prompt, return_tensors="pt", max_length=512, truncation=True)
        
        with torch.no_grad():
            outputs = self.model.generate(
                inputs,
                **self.generation_config
            )
        
        full_response = self.tokenizer.decode(outputs[0], skip_special_tokens=True)
        assistant_response = self.extract_assistant_response(full_response, prompt)
        
        return self.post_process_response(assistant_response)

# Usage example
def test_chatbot():
    """Test the enhanced chatbot"""
    chatbot = VoiceUPIChatbot("models/voiceupi_chatbot")
    
    test_inputs = [
        "Hello",
        "How do I send money?",
        "Send 500 to John",
        "What is UPI?",
        "Is voice payment safe?",
        "Check my balance"
    ]
    
    conversation_history = []
    
    print("Testing VoiceUPI Chatbot:")
    print("=" * 50)
    
    for user_input in test_inputs:
        response = chatbot.get_contextual_response(user_input, conversation_history)
        print(f"User: {user_input}")
        print(f"Bot: {response}")
        print("-" * 30)
        
        # Add to conversation history
        conversation_history.append({
            "user": user_input,
            "assistant": response
        })

if __name__ == "__main__":
    test_chatbot()
