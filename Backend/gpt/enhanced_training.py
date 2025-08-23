import os
import pandas as pd
from datasets import Dataset
from transformers import AutoTokenizer, AutoModelForCausalLM, DataCollatorForLanguageModeling, Trainer, TrainingArguments
import torch
from datetime import datetime

# Enhanced configuration for better performance
MODEL_NAME = "microsoft/DialoGPT-small"  # Better for conversations than GPT2
DATA_PATH = "./trianing.csv"
OUTPUT_DIR = "models/voiceupi_chatbot"
MAX_LEN = 256  # Longer context for better conversations
EPOCHS = 8     # More epochs for better learning
BATCH_SIZE = 4 # Smaller batch for better gradient updates
LEARNING_RATE = 3e-5  # Lower learning rate for stability

# Load and preprocess data with better formatting
df = pd.read_csv(DATA_PATH)
assert {"input", "response"}.issubset(df.columns), "CSV must have 'input' and 'response' columns."

def build_conversation_prompt(row):
    """Enhanced prompt format for better conversation flow"""
    user_input = row['input'].strip()
    assistant_response = row['response'].strip()
    
    # Add special tokens for better conversation understanding
    return f"<|user|>{user_input}<|assistant|>{assistant_response}<|endofturn|>"

# Create enhanced dataset
df["text"] = df.apply(build_conversation_prompt, axis=1)

# Add data validation and cleaning
def clean_text(text):
    """Clean and validate text data"""
    text = text.replace('\n', ' ').replace('\r', ' ')
    text = ' '.join(text.split())  # Remove extra whitespace
    return text

df["text"] = df["text"].apply(clean_text)

# Filter out very short or long responses
df = df[(df["text"].str.len() > 10) & (df["text"].str.len() < 500)]

dataset = Dataset.from_pandas(df[["text"]])
print(f"Dataset size after cleaning: {len(dataset)}")

# Enhanced tokenizer setup
tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)

# Add special tokens for conversation structure
special_tokens = {
    "additional_special_tokens": ["<|user|>", "<|assistant|>", "<|endofturn|>"]
}
tokenizer.add_special_tokens(special_tokens)

if tokenizer.pad_token is None:
    tokenizer.pad_token = tokenizer.eos_token

# Load model and resize embeddings for new tokens
model = AutoModelForCausalLM.from_pretrained(MODEL_NAME)
model.resize_token_embeddings(len(tokenizer))

# Enhanced tokenization with better attention masks
def enhanced_tokenize(batch):
    tokenized = tokenizer(
        batch["text"],
        truncation=True,
        max_length=MAX_LEN,
        padding="max_length",
        return_tensors=None,
    )
    
    # Set labels for causal language modeling
    tokenized["labels"] = tokenized["input_ids"].copy()
    
    return tokenized

tokenized_dataset = dataset.map(enhanced_tokenize, batched=True, remove_columns=["text"])

# Split dataset for validation
train_test_split = tokenized_dataset.train_test_split(test_size=0.1, seed=42)
train_dataset = train_test_split["train"]
eval_dataset = train_test_split["test"]

print(f"Training examples: {len(train_dataset)}")
print(f"Validation examples: {len(eval_dataset)}")

# Enhanced data collator
collator = DataCollatorForLanguageModeling(
    tokenizer=tokenizer,
    mlm=False,
)

# Improved training arguments
training_args = TrainingArguments(
    output_dir=OUTPUT_DIR,
    overwrite_output_dir=True,
    
    # Training parameters
    per_device_train_batch_size=BATCH_SIZE,
    per_device_eval_batch_size=BATCH_SIZE,
    num_train_epochs=EPOCHS,
    learning_rate=LEARNING_RATE,
    weight_decay=0.01,
    warmup_steps=100,
    
    # Evaluation and logging
    evaluation_strategy="steps",
    eval_steps=50,
    logging_steps=25,
    save_steps=100,
    save_total_limit=3,
    
    # Performance optimizations
    fp16=False,  # Set to True if you have a compatible GPU
    dataloader_num_workers=2,
    
    # Early stopping and monitoring
    load_best_model_at_end=True,
    metric_for_best_model="eval_loss",
    greater_is_better=False,
    
    # Reporting
    report_to=[],
    run_name=f"voiceupi_chatbot_{datetime.now().strftime('%Y%m%d_%H%M')}",
)

# Enhanced trainer with evaluation
trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=train_dataset,
    eval_dataset=eval_dataset,
    data_collator=collator,
    tokenizer=tokenizer,
)

# Train the model
print("Starting training...")
trainer.train()

# Save the final model
print("Saving model...")
os.makedirs(OUTPUT_DIR, exist_ok=True)
trainer.save_model(OUTPUT_DIR)
tokenizer.save_pretrained(OUTPUT_DIR)

print(f"✅ Training completed! Model saved to: {OUTPUT_DIR}")

# Evaluation metrics
print("\nEvaluating model...")
eval_results = trainer.evaluate()
print(f"Final evaluation loss: {eval_results['eval_loss']:.4f}")
